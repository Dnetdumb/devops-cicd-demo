# Workflow:

```bash
	ESO
	  |	- Send request to Vault and every "Refresh Interval" with auth method Kubernetes
	  ▼
	Vault
	  |	- Grant ESO a Token with specific policy and role
	  ▼
	ESO
	  |	- Use this "Token" to request a username/password of Postgres
	  ▼
        Vault
	  |	- Use "vaultadmin" to create role on CloudNativePG (primary Pod) with special interval and Grant to ESO
	  ▼
	ESO
	  |	- Sync this username/password to K8s
	  ▼
	Pod	- Reload secret by restarting with reloader:true
```
# VAULT SECRET MANAGER

## Install Vault Secret Manager through Helm
```bash
# Add repo and update:

helm repo add hashicorp https://helm.releases.hashicorp.com

helm repo update

# Apply PV (persistence volume):

kubectl apply -f pv-vault.yaml

# Install:

helm install vault hashicorp/vault \
  --namespace vault --create-namespace \
  --set "server.ha.enabled=true" \
  --set "server.ha.raft.enabled=true" \
  --set "server.dataStorage.size=1Gi" \
  --set "ui.enabled=true"

# Default statefulset replicas=3 -> High Availability (should 3,5,7)
#			         -> 1 Leader, 2 Followers

# Leader: Create new secret, update password, ...
# Followers: one of will be promote to Leader 


kubectl scale statefulset vault --replicas=1 -n vault

# Check:
kubectl get sa,pvc,pods,deploy,svc,sts -n vault

NAME                                  SECRETS   AGE
serviceaccount/default                0         16m
serviceaccount/vault                  0         15m
serviceaccount/vault-agent-injector   0         15m

NAME                                 STATUS   VOLUME            CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/data-vault-0   Bound    pv-data-vault-0   1Gi        RWO                           <unset>                 15m

NAME                                       READY   STATUS    RESTARTS   AGE
pod/vault-0                                0/1     Running   0          15m
pod/vault-agent-injector-8d6b668b4-ztsbz   1/1     Running   0          15m

NAME                                   READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/vault-agent-injector   1/1     1            1           15m

NAME                               TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE
service/vault                      ClusterIP   10.109.242.163   <none>        8200/TCP,8201/TCP   15m
service/vault-active               ClusterIP   10.103.14.229    <none>        8200/TCP,8201/TCP   15m
service/vault-agent-injector-svc   ClusterIP   10.110.118.32    <none>        443/TCP             15m
service/vault-internal             ClusterIP   None             <none>        8200/TCP,8201/TCP   15m
service/vault-standby              ClusterIP   10.102.231.38    <none>        8200/TCP,8201/TCP   15m
service/vault-ui                   ClusterIP   10.103.196.244   <none>        8200/TCP            15m

NAME                     READY   AGE
statefulset.apps/vault   0/1     15m

```
## Initialize vault to get Un-Sealed key
```bash
kubectl exec -it -n vault vault-0 -- vault operator init

# Verify and Save these key:

kubectl exec -it -n vault vault-0 -- vault operator init

Unseal Key 1: IC4S4a61.....
Unseal Key 2: 1IgqeWKb.....
Unseal Key 3: 0tqpu+Gr.....
Unseal Key 4: safpMLdO.....
Unseal Key 5: MSiAOxs7.....

Initial Root Token: hvs.LkWY.....

Vault initialized with 5 key shares and a key threshold of 3. Please securely
distribute the key shares printed above. When the Vault is re-sealed,
restarted, or stopped, you must supply at least 3 of these keys to unseal it
before it can start servicing requests.

Vault does not store the generated root key. Without at least 3 keys to
reconstruct the root key, Vault will remain permanently sealed!

It is possible to generate new unseal keys, provided you have a quorum of
existing unseal keys shares. See "vault operator rekey" for more information.

```

## Un-Sealed with 3/5 Unseal key
```bash
kubectl exec -it -n vault vault-0 -- vault operator unseal <Unseal Key 1>

kubectl exec -it -n vault vault-0 -- vault operator unseal <Unseal Key 2>

kubectl exec -it -n vault vault-0 -- vault operator unseal <Unseal Key 3>

# Verify now readiness probe was success:

kubectl get pods -n vault

NAME                                       READY   STATUS    RESTARTS   AGE
pod/vault-0                                1/1     Running   0          17m
pod/vault-agent-injector-8d6b668b4-ztsbz   1/1     Running   0          17m

```

# EXTERNAL SECRET OPERATOR (ESO)

## Install through Helm
```bash
helm repo add external-secrets https://charts.external-secrets.io

helm install external-secrets external-secrets/external-secrets -n vault --create-namespace

# Install:

helm install external-secrets external-secrets/external-secrets -n vault --create-namespace --version 0.10.7

# Check:

kubectl get pods,deploy,sa,svc -n vault -l app.kubernetes.io/instance=e
xternal-secrets
NAME                                                   READY   STATUS    RESTARTS   AGE
pod/external-secrets-6bfcb97cf8-m7lps                  1/1     Running   0          2m49s
pod/external-secrets-cert-controller-fb85544ff-mhzsz   1/1     Running   0          2m49s
pod/external-secrets-webhook-6784b877d4-76v8q          1/1     Running   0          2m49s

NAME                                               READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/external-secrets                   1/1     1            1           2m50s
deployment.apps/external-secrets-cert-controller   1/1     1            1           2m50s
deployment.apps/external-secrets-webhook           1/1     1            1           2m50s

NAME                                              SECRETS   AGE
serviceaccount/external-secrets                   0         2m51s
serviceaccount/external-secrets-cert-controller   0         2m51s
serviceaccount/external-secrets-webhook           0         2m51s

NAME                               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/external-secrets-webhook   ClusterIP   10.103.48.42   <none>        443/TCP   2m50s
```

## Create user "vaultadmin" on Postgres with specific CREATE ROLE only
```bash
kubectl exec -it -n demo pg-cluster-3 -- bash

psql -U postgres

CREATE ROLE vaultadmin WITH LOGIN PASSWORD 'V@ult123';

ALTER ROLE vaultadmin WITH CREATEROLE;
```

## Create another role on Postgres that can write/read mydb
```bash
CREATE ROLE db_app_role NOLOGIN;

\c mydb;

-- Cấp full quyền cho db_app_role trên database mydb
GRANT ALL PRIVILEGES ON DATABASE mydb TO db_app_role;

-- Cấp quyền thao tác trên schema public hiện tại
GRANT ALL PRIVILEGES ON SCHEMA public TO db_app_role;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO db_app_role;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO db_app_role;

-- Ép các bảng/sequences tạo mới sau này tự động share quyền cho db_app_role
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO db_app_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO db_app_role;
```

## Login to Vault with Initial Root Token
```bash
kubectl exec -it -n vault vault-0 -- /bin/sh

export VAULT_TOKEN=<Initial Root Token>
```

### Enable Auth method Kubernetes on Vault
```bash
vault auth enable kubernetes

Success! Enabled kubernetes auth method at: kubernetes/


vault write auth/kubernetes/config \
    token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    kubernetes_host="https://kubernetes.default:443"\
    kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

Success! Data written to: auth/kubernetes/config
```

### Enable database engine on Vault
```bash
vault secrets enable database

/ $ vault secrets enable database
Success! Enabled the database secrets engine at: database/
```

### Create policy (The place database engine will create secret)
```bash
vault policy write webapp-policy - <<EOF
path "database/creds/*" {
  capabilities = ["read"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

Success! Uploaded policy: webapp-policy
```

### Create role (Link K8s Service Account with Vault policy) 
```bash
vault write auth/kubernetes/role/webapp-role \
    bound_service_account_names=external-secrets \
    bound_service_account_namespaces=vault \
    policies=webapp-policy \
    token_no_default_policy=true \
    token_ttl=1h \
    token_max_ttl=24h \
    token_type=default
```
 
### Define SecretStore 
```bash
kubectl apply -f cluster-secret-store.yaml

#Verify:

kubectl get css -n demo

NAME            AGE   STATUS   CAPABILITIES   READY
vault-db-store   5s    Valid    ReadWrite      True
```

### Define user "vaultadmin" on Vault
```bash
vault write database/config/cnpg-db \
    plugin_name=postgresql-database-plugin \
    allowed_roles="webapp-role" \
    connection_url="postgresql://{{username}}:{{password}}@pg-cluster-rw.demo.svc.cluster.local:5432/mydb?sslmode=disable" \
    username="vaultadmin" \
    password="V@ult123"

Success! Data written to: database/config/cnpg-db
```
### Define how to create a user on Postgres when ESO request
```bash
vault write database/roles/webapp-role \
    db_name=cnpg-db \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; GRANT db_app_role TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="8h"

Success! Data written to: database/roles/webapp-role
```

### Define how ESO sync secret to Kubernetes

```bash
kubectl apply -f external-secret.yaml

```

## Result:

```bash
mydb=> \du
                                                          List of roles
                      Role name                      |                         Attributes                         |   Member of
-----------------------------------------------------+------------------------------------------------------------+---------------
 app                                                 |                                                            | {}
 db_app_role                                         | Cannot login                                               | {}
 postgres                                            | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 streaming_replica                                   | Replication                                                | {}
 v-kubernet-webapp-r-kRjUrNXPiOIp9vkUqIVm-1779967565 | Password valid until 2026-05-28 12:26:10+00                | {db_app_role}
 vaultadmin                                          | Superuser, Create role, Create DB                          | {db_app_role}


# Force External Secret Sync now:

kubectl annotate externalsecret db-sync -n demo force-sync=$(date +%s) --overwrite

# Check database:

mydb=> \du
                                                          List of roles
                      Role name                      |                         Attributes                         |   Member of
-----------------------------------------------------+------------------------------------------------------------+---------------
 app                                                 |                                                            | {}
 db_app_role                                         | Cannot login                                               | {}
 postgres                                            | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
 streaming_replica                                   | Replication                                                | {}
 v-kubernet-webapp-r-EUkoXw0Dr3pHQRTs2IEs-1779972473 | Password valid until 2026-05-28 13:47:58+00                | {db_app_role}
 v-kubernet-webapp-r-mBPiALoSQj2SceWV2MWX-1779972349 | Password valid until 2026-05-28 13:45:54+00                | {db_app_role}
 v-kubernet-webapp-r-rtAFxbDC4jBefZo3iDQU-1779971718 | Password valid until 2026-05-28 13:35:23+00                | {db_app_role}
 vaultadmin                                          | Superuser, Create role, Create DB                          | {db_app_role}


# Check logs reloader:

kubectl logs -n kube-system reloader-reloader-54c988d968-hgd29 -f
...
...
time="2026-05-28T12:45:49Z" level=info msg="Changes detected in 'postgres-secret' of type 'SECRET' in namespace 'demo'; updated 'backend' of type 'Deployment' in namespace 'demo'"
time="2026-05-28T12:47:54Z" level=info msg="Changes detected in 'postgres-secret' of type 'SECRET' in namespace 'demo'; updated 'backend' of type 'Deployment' in namespace 'demo'"
