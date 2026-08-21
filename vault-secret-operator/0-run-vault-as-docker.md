# Vault Docker Images
docker pull hashicorp/vault-enterprise:1.19.8-ent
docker pull hashicorp/vault-enterprise:1.20.1-ent
docker pull hashicorp/vault-enterprise:1.21.3-ent # enterprise
docker pull hashicorp/vault:1.21 # opensource

# Vault License
export VAULT_LICENSE=     

# `disable ipv6` - and `-p 127.0.0.1:8200:8200` - and connect to docker bridge `kind`
docker run --name vault-oss-cluster \
  --cap-add=IPC_LOCK \
  --sysctl net.ipv6.conf.all.disable_ipv6=1 \
  --env VAULT_DEV_ROOT_TOKEN_ID=root \
  --env VAULT_DEV_LISTEN_ADDRESS=0.0.0.0:8200 \
  --publish 127.0.0.1:8200:8200 \
  --network kind \
  --ip 172.18.0.10 \
  --detach \
  hashicorp/vault:1.21


export VAULT_ADDR=http://172.18.0.10:8200
export VAULT_TOKEN=root

vault auth list
vault secrets list
