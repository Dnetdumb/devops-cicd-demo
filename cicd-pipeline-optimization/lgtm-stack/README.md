### Apply loki custom policy in minIO 
```bash
mc admin policy create myminio loki-custom-policy loki-custom-policy.json
Created policy `loki-custom-policy` successfully.

mc admin policy info myminio loki-custom-policy
{
 "PolicyName": "loki-custom-policy",
 "Policy": {
  "Version": "2012-10-17",
  "Statement": [
   {
    "Effect": "Allow",
    "Action": [
     "s3:ListBucket",
     "s3:PutObject",
     "s3:DeleteObject",
     "s3:GetBucketLocation",
     "s3:GetObject"
    ],
    "Resource": [
     "arn:aws:s3:::loki-admin/*",
     "arn:aws:s3:::loki-chunks",
     "arn:aws:s3:::loki-chunks/*",
     "arn:aws:s3:::loki-index",
     "arn:aws:s3:::loki-index/*",
     "arn:aws:s3:::loki-ruler",
     "arn:aws:s3:::loki-ruler/*",
     "arn:aws:s3:::loki-admin"
    ]
   }
  ]
 },
 "CreateDate": "2026-05-08T11:29:55.374Z",
 "UpdateDate": "2026-05-08T11:29:55.374Z"
}

```

### Create user "loki" on MinIO and attach policy 
```bash
/mc admin user add myminio loki loki12345
Added user `loki` successfully.

/mc admin policy attach myminio loki-custom-policy --user loki
Attached Policies: [loki-custom-policy]
To User: loki

mc admin user ls myminio
enabled    backup                readwrite
enabled    loki                  loki-custom-policy

```
