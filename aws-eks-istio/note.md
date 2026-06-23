How to find them
1. DNS lookup (simplest — this is what curl did):


NLB=a772de9bae81e48f388df55f894f1732-65f36a83576ff9f8.elb.ap-southeast-1.amazonaws.com
dig +short "$NLB"
# or: nslookup "$NLB"   |   host "$NLB"   |   getent hosts "$NLB"
That's the one I just ran — same three IPs.

2. From the NLB hostname via kubectl (get the hostname, then resolve):


kubectl -n global-istio-ingress get svc global-istio-ingressgateway \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
3. From AWS directly (ties the IPs to the actual load balancer + its network interfaces):


# find the NLB by its DNS name
aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='$NLB'].[LoadBalancerName,Type,AvailabilityZones[].ZoneName]"

# the public IPs live on the NLB's ENIs (one per AZ):
aws ec2 describe-network-interfaces \
  --filters "Name=description,Values=ELB net/*" \
  --query "NetworkInterfaces[?contains(Description,'$(echo $NLB | cut -d- -f1)')].[AvailabilityZone,Association.PublicIp,PrivateIpAddress]" \
  --output table --profile demo-microservice
Why it matters
These IPs are AWS-managed and can change (the NLB replaces nodes on scaling/failure), so never hardcode them — always use the DNS name.
For grc.ky-cloud.click, create a CNAME → the NLB hostname (not an A record to these IPs), so DNS keeps following the NLB if the IPs change.
If you ever need stable IPs (e.g., for a firewall allowlist), that requires assigning Elastic IPs to the NLB — which means recreating it with the aws-load-balancer-eip-allocations annotation.
Want me to add the grc.ky-cloud.click CNAME guidance to the README, or help set up the DNS record?