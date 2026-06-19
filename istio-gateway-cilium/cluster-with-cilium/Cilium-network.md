Who assigns what
1. The Cilium Operator (runs once for the cluster, cilium-operator pod) carves the address space into per-node slices. With cluster-pool defaults it takes the pool 10.0.0.0/8 and cuts a /24 per node, writing each slice onto that node's CiliumNode CRD:

Node	PodCIDR the operator assigned
control-plane	10.0.0.0/24
worker	10.0.1.0/24
worker2	10.0.2.0/24
worker3	10.0.3.0/24
2. The Cilium agent (the cilium DaemonSet pod on each node) then picks the router IP — cilium_host — out of its own node's /24 and assigns it to the interface:

10.0.0.207 ∈ 10.0.0.0/24 → control-plane
10.0.1.9 ∈ 10.0.1.0/24 → worker
10.0.2.129 ∈ 10.0.2.0/24 → worker2
10.0.3.183 ∈ 10.0.3.0/24 → worker3
The agent also assigns each real pod an IP from the same /24, using cilium_host as their gateway.

The gotcha worth noticing
Your kind-config.yaml declares podSubnet: 10.244.0.0/16, but your actual pod IPs are 10.0.x.x. That's because cluster-pool IPAM ignores node.Spec.PodCIDR (the kind/kube-controller-manager value) and uses Cilium's own default pool 10.0.0.0/8 instead. So:

If you were in ipam.mode=kubernetes, the kube-controller-manager (node-ipam-controller) would assign each node's PodCIDR from kind's 10.244.0.0/16, and Cilium would just consume it. You'd see 10.244.x.x.
Because you're in cluster-pool (the default, since nothing was set), the Cilium Operator is the authority, and the 10.244.0.0/16 in your kind config is effectively dead config.
So the short answer: the Cilium Operator assigns the per-node CIDRs, and each node's Cilium agent assigns the cilium_host IP (and pod IPs) within that CIDR. Kubernetes/kind isn't involved in these particular addresses at all.

This is also why those IPs shift after a Docker/host restart — the operator re-allocates from the pool on a fresh start, which is exactly the stale-IP situation behind your cluster-restart recovery steps.

One thing you may want to fix for clarity: either set --set ipam.operator.clusterPoolIPv4PodCIDRList=10.244.0.0/16 to make Cilium honor your kind podSubnet, or drop/annotate the misleading podSubnet so the two configs stop disagreeing. Want me to add a note about this to setup.md?


Here are the commands to verify each claim, top to bottom.

1. Confirm the IPAM mode is cluster-pool

kubectl -n kube-system get configmap cilium-config -o jsonpath='{.data.ipam}{"\n"}'
# expect: cluster-pool

# and the pool + per-node mask the operator uses:
kubectl -n kube-system get configmap cilium-config \
  -o jsonpath='cluster-pool-cidr: {.data.cluster-pool-ipv4-cidr}{"\n"}mask-size: {.data.cluster-pool-ipv4-mask-size}{"\n"}'
# expect something like 10.0.0.0/8 and 24
2. See the per-node CIDRs the Operator assigned

kubectl get ciliumnodes -o custom-columns=\
NODE:.metadata.name,PODCIDRS:.spec.ipam.podCIDRs
This is the authoritative Cilium view. You should see 10.0.0.0/24, 10.0.1.0/24, etc.

3. Prove Kubernetes/kind's PodCIDR is different (the dead 10.244 config)

kubectl get nodes -o custom-columns=\
NODE:.metadata.name,K8S_PODCIDR:.spec.podCIDR
These will show 10.244.x.x (from kind), confirming Cilium is ignoring them in cluster-pool mode.

4. See the cilium_host router IP the agent picked per node

for node in idp-cluster-control-plane idp-cluster-worker idp-cluster-worker2 idp-cluster-worker3; do
  echo "=== $node ==="
  docker exec $node ip addr show cilium_host | grep "inet "
done
(what you already ran) — each IP falls inside the matching CIDR from step 2.

Or straight from Cilium's own status:


kubectl -n kube-system get ciliumnodes \
  -o custom-columns=NODE:.metadata.name,ROUTER_IP:.spec.addresses
5. Cross-check from inside a Cilium agent

# pick one agent pod
kubectl -n kube-system get pods -l k8s-app=cilium -o wide

kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose | grep -A6 'IPAM:'
The IPAM: block lists the allocated pod CIDR and how many IPs are in use on that node.

6. Confirm a real pod gets an IP from the same /24

kubectl get pods -A -o wide --field-selector spec.nodeName=idp-cluster-worker \
  | awk '{print $1, $2, $7}'
Pod IPs should all be 10.0.1.x (same /24 as worker's cilium_host 10.0.1.9).

The clincher is steps 2 vs 3: ciliumnodes shows 10.0.x.x while nodes -o ...podCIDR shows 10.244.x.x. That side-by-side is the direct proof that the Cilium Operator — not kube-controller-manager — is the one assigning these addresses.

