# create 3 x k8s clusters `kv-cluster` `db-cluster` `pki-cluster`

cd /home/sai/pov-vault/vso-pov-MAR2026-v1/kindsetup
./setupkindcluster132.sh #kv-cluster 172.18.0.3:6443
./setupkindcluster133.sh #db-cluster 172.18.0.5:6443
./setupkindcluster134.sh #pki-cluster 172.18.0.7:6443

k config get-contexts
CURRENT   NAME          CLUSTER            AUTHINFO           NAMESPACE
          db-cluster    kind-db-cluster    kind-db-cluster    
          kv-cluster    kind-kv-cluster    kind-kv-cluster    
*         pki-cluster   kind-pki-cluster   kind-pki-cluster 

k get nodes -o wide --context kv-cluster 
NAME                       STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION             CONTAINER-RUNTIME
kv-cluster-control-plane   Ready    control-plane   4m53s   v1.32.8   172.18.0.3    <none>        Debian GNU/Linux 12 (bookworm)   6.12.10-76061203-generic   containerd://2.1.3
kv-cluster-worker          Ready    <none>          4m44s   v1.32.8   172.18.0.4    <none>        Debian GNU/Linux 12 (bookworm)   6.12.10-76061203-generic   containerd://2.1.3

kubectl get nodes -o wide --context db-cluster
NAME                       STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION             CONTAINER-RUNTIME
db-cluster-control-plane   Ready    control-plane   3m26s   v1.33.4   172.18.0.5    <none>        Debian GNU/Linux 12 (bookworm)   6.12.10-76061203-generic   containerd://2.1.3
db-cluster-worker          Ready    <none>          3m16s   v1.33.4   172.18.0.6    <none>        Debian GNU/Linux 12 (bookworm)   6.12.10-76061203-generic   containerd://2.1.3

NAME                        STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION             CONTAINER-RUNTIME
pki-cluster-control-plane   Ready    control-plane   2m35s   v1.34.0   172.18.0.7    <none>        Debian GNU/Linux 12 (bookworm)   6.12.10-76061203-generic   containerd://2.1.3
pki-cluster-worker          Ready    <none>          2m25s   v1.34.0   172.18.0.8    <none>        Debian GNU/Linux 12 (bookworm)   6.12.10-76061203-generic   containerd://2.1.3

### Run `helm repo update`
### Run `helm search repo hashicorp/vault-secrets-operator`
### `helm search repo hashicorp/vault-secrets-operator --versions`

NAME                                    CHART VERSION   APP VERSION     DESCRIPTION                          
hashicorp/vault-secrets-operator        1.3.0           1.3.0           Official Vault Secrets Operator Chart

### Pull the Helm Chart and Untar

helm pull hashicorp/vault-secrets-operator --version 1.3.0 --untar --untardir vso-helmchart-v1.3.0


# Deploy `vso` on all k8s clusters

# install vso on `kv-cluster`
helm install vault-secrets-operator hashicorp/vault-secrets-operator --namespace vso --create-namespace --kube-context kv-cluster

# install vso on `db-cluster`
helm install vault-secrets-operator hashicorp/vault-secrets-operator --namespace vso --create-namespace --kube-context db-cluster

# install vso on `pki-cluster`
helm install vault-secrets-operator hashicorp/vault-secrets-operator --namespace vso --create-namespace --kube-context pki-cluster


# verify vso installation
# kubectl get all -n vso --context kv-cluster

NAME                                                            READY   STATUS    RESTARTS   AGE
pod/vault-secrets-operator-controller-manager-96dd89f78-9ncmc   2/2     Running   0          49s

NAME                                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/vault-secrets-operator-metrics-service   ClusterIP   10.132.171.22   <none>        8443/TCP   49s

NAME                                                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/vault-secrets-operator-controller-manager   1/1     1            1           49s

NAME                                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/vault-secrets-operator-controller-manager-96dd89f78   1         1         1       49s


# k get all -n vso --context db-cluster

NAME                                                            READY   STATUS    RESTARTS   AGE
pod/vault-secrets-operator-controller-manager-96dd89f78-zkv95   2/2     Running   0          57s

NAME                                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/vault-secrets-operator-metrics-service   ClusterIP   10.133.214.16   <none>        8443/TCP   57s

NAME                                                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/vault-secrets-operator-controller-manager   1/1     1            1           57s

NAME                                                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/vault-secrets-operator-controller-manager-96dd89f78   1         1         1       57s



# k get all -n vso --context pki-cluster
NAME                                                             READY   STATUS    RESTARTS   AGE
pod/vault-secrets-operator-controller-manager-746c5dd9bd-6svb7   2/2     Running   0          83s

NAME                                             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
service/vault-secrets-operator-metrics-service   ClusterIP   10.134.168.165   <none>        8443/TCP   83s

NAME                                                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/vault-secrets-operator-controller-manager   1/1     1            1           83s

NAME                                                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/vault-secrets-operator-controller-manager-746c5dd9bd   1         1         1       83s