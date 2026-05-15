## Install Tempo with custom values.yaml (simpleScalabled mode)

### Add Helm repo
```bash
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
```
### Helm install tempo with custom values.yaml
```bash
helm install tempo grafana/tempo -n monitoring -f values.yaml 

# helm install tempo-distributed grafana/tempo -n monitoring -f values.yaml
# Distributed Mode: 
# 	tempo-distributor
#	tempo-ingester
#	tempo-querier
#	tempo-query-frontend

```
## Apply custom policy for user tempo on minIO 
```bash
mc admin policy create minio-admin tempo-custom-policy tempo-custom-policy.json

mc admin policy info minio-admin tempo-custom-policy
{
 "PolicyName": "tempo-custom-policy",
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
     "arn:aws:s3:::tempo-data",
     "arn:aws:s3:::tempo-data/*"
    ]
   }
  ]
 },
 "CreateDate": "2026-05-12T08:48:23.24Z",
 "UpdateDate": "2026-05-12T08:48:23.24Z"
}
```
## Using mc command (minio client) to create user "tempo" on MinIO and attach policy 
```bash
mc admin user add minio-admin tempo tempo12345
Added user `tempo` successfully.

mc admin policy attach minio-admin tempo-custom-policy --user tempo
Attached Policies: [tempo-custom-policy]
To User: tempo

mc admin user ls minio-admin
enabled    tempo                 tempo-custom-policy
enabled    backup                backup-custom-policy
enabled    loki                  loki-custom-policy
```

<img width="2557" height="1378" alt="attach7" src="https://github.com/user-attachments/assets/8fa53a4e-5d25-460d-a5c0-a5f893101594" />

