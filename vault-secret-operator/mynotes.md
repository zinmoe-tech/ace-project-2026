kubectl config get-contexts #Chech how many clustes we have

# delete specific cluster
kind delete cluster --name pki-cluster

# or delete all clusters at once
kind delete clusters --all

kubectl get nodes --context kv-cluster

kubectl get secret -n kvcluster-vaultconn --context kv-cluster