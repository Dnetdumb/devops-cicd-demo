## Install loki with custom values.yaml (simpleScalabled mode)

### Add Helm repo
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```
### Apply pv (persistent volume) for loki-write and loki-backend
```bash
kubectl apply -f pv-loki.yaml

persistentvolume/pv-loki-write created
persistentvolume/pv-loki-backend created
```
### Helm install loki with custom values.yaml
```bash
helm install loki grafana/loki -n monitoring -f values.yaml

# Verify:
kubectl get pvc -n monitoring

NAME                  STATUS   VOLUME            CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
data-loki-backend-0   Bound    pv-loki-backend   1Gi        RWO                           <unset>                 12m
data-loki-write-0     Bound    pv-loki-write     1Gi        RWO                           <unset>                 12m

kubectl get pods,deploy,sts -n monitoring -l app.kubernetes.io/name=loki

NAME                              READY   STATUS    RESTARTS   AGE
pod/loki-backend-0                2/2     Running   0          5m2s
pod/loki-canary-4szqc             1/1     Running   0          5m2s
pod/loki-canary-df67j             1/1     Running   0          5m2s
pod/loki-gateway-66bbdb6d-xhcpq   1/1     Running   0          5m2s
pod/loki-read-558d79fb95-4gdgz    1/1     Running   0          5m2s
pod/loki-write-0                  1/1     Running   0          5m2s

NAME                           READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/loki-gateway   1/1     1            1           5m2s
deployment.apps/loki-read      1/1     1            1           5m2s

NAME                            READY   AGE
statefulset.apps/loki-backend   1/1     5m2s
statefulset.apps/loki-write     1/1     5m2s
```
## Apply custom policy for user loki on minIO 
```bash
mc admin policy create minio-admin loki-custom-policy loki-custom-policy.json

mc admin policy info minio-admin loki-custom-policy
{
 "PolicyName": "loki-custom-policy",
 "Policy": {
  "Version": "2012-10-17",
  "Statement": [
   {
    "Effect": "Allow",
    "Action": [
     "s3:DeleteObject",
     "s3:GetBucketLocation",
     "s3:GetObject",
     "s3:ListBucket",
     "s3:PutObject"
    ],
    "Resource": [
     "arn:aws:s3:::loki-admin",
     "arn:aws:s3:::loki-admin/*",
     "arn:aws:s3:::loki-chunks",
     "arn:aws:s3:::loki-chunks/*",
     "arn:aws:s3:::loki-ruler",
     "arn:aws:s3:::loki-ruler/*"
    ]
   }
  ]
 },
 "CreateDate": "2026-05-08T11:29:55.374Z",
 "UpdateDate": "2026-05-11T10:16:19.733Z"
}
```

## Using mc command (minio client) to create user "loki" on MinIO and attach policy 
```bash
mc admin user add minio-admin loki loki12345
Added user `loki` successfully.

mc admin policy attach minio-admin loki-custom-policy --user loki
Attached Policies: [loki-custom-policy]
To User: loki

mc admin user ls minio-admin
enabled    backup                backup-custom-policy
enabled    loki                  loki-custom-policy
```

<img width="2553" height="1387" alt="attach6" src="https://github.com/user-attachments/assets/f9e6d353-c1ba-463e-b225-15d48a5d3548" />

