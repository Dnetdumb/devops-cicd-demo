# CloudNativePG (cnpg operator)

## Architect:
```bash
Database: CloudNativePG (cnpg) - cluster-cnpg.yaml

- HighAvailability: 
	Deployment: 1 Pod role Primary, N Pod role Replica
	Service/Routing: Only route traffic depend on role {Replica/Primary}-{READ/WRITE} 
	Syncing: using WAL streaming on Postgres to 
		client (write) -> Pod primary (write into WAL) -> WAL (streaming TCP to replicas) -> Pod replicas (replay to get data) 

- Read/Write Split: already define in code logic (http://github.com/Dnetdumb/devops-cicd-demo/cicd-pipeline-optimization/postgres.js)

- Backup: Using Barman Cloud to push backup object (base + WAL archive) to MinIO (s3 compatible storage)

```

## Add CloudNativePG from helm

### Add and Update Helm repo
```bash
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm repo update
```
### Install CNPG Operator
```bash
helm install cnpg-operator cnpg/cloudnative-pg -n demo --create-namespace
```
### Verify operator status 
```bash
kubectl get deploy,sts,svc,pods -n demo

NAME                                           READY   UP-TO-DATE   AVAILABLE
deployment.apps/cnpg-operator-cloudnative-pg   1/1     1            1

NAME                           TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
service/cnpg-webhook-service   ClusterIP   10.110.106.26   <none>        443/TCP

NAME                                                READY   STATUS    RESTARTS 
pod/cnpg-operator-cloudnative-pg-68f8b94b45-kc6sc   1/1     Running   16 (10m ago)
```
## Apply PV (Persistent Volume) for pg-cluster 
```bash
kubectl apply -f pv-cnpg.yaml

persistentvolume/pg-pv-pri created
persistentvolume/pg-pv-rep1 created
persistentvolume/pg-pv-rep2 created

# Verify:
kubectl get pv -n demo

NAME         CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM               STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pg-pv-pri    1Gi        RWO            Retain           Available   demo/pg-cluster-1   manual         <unset>                          27s
pg-pv-rep1   1Gi        RWO            Retain           Available   demo/pg-cluster-2   manual         <unset>                          27s
pg-pv-rep2   1Gi        RWO            Retain           Available   demo/pg-cluster-3   manual         <unset>                          27s
pv-minio     10Gi       RWO            Retain           Bound       demo/data-minio-0   manual         <unset>                          20m
```


## Apply cluster "pg-cluster"
```bash
kubectl get pods,pvc -n demo -l cnpg.io/cluster=pg-cluster

NAME               READY   STATUS    RESTARTS   AGE
pod/pg-cluster-1   1/1     Running   0          2m23s
pod/pg-cluster-2   1/1     Running   0          2m4s
pod/pg-cluster-3   1/1     Running   0          105s

NAME                                 STATUS   VOLUME       CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/pg-cluster-1   Bound    pg-pv-pri    1Gi        RWO                           <unset>                 2m29s
persistentvolumeclaim/pg-cluster-2   Bound    pg-pv-rep1   1Gi        RWO                           <unset>                 2m12s
persistentvolumeclaim/pg-cluster-3   Bound    pg-pv-rep2   1Gi        RWO                           <unset>                 112s
```
## Check bucket on MinIO
attach3.png

## Apply backup secret on K8s (use for CNPG login to MinIO backup data)
```bash
kubectl apply -f minio-backup-secret.yaml
```
## Apply custom policy for user backup on minIO
```bash
mc admin policy create minio-admin backup-custom-policy backup-custom-policy.json

mc admin policy info minio-admin backup-custom-policy
{
 "PolicyName": "backup-custom-policy",
 "Policy": {
  "Version": "2012-10-17",
  "Statement": [
   {
    "Effect": "Allow",
    "Action": [
     "s3:GetBucketLocation",
     "s3:GetObject",
     "s3:ListBucket",
     "s3:PutObject",
     "s3:DeleteObject"
    ],
    "Resource": [
     "arn:aws:s3:::cnpg-bucket",
     "arn:aws:s3:::cnpg-bucket/*"
    ]
   }
  ]
 },
 "CreateDate": "2026-05-11T10:23:07.573Z",
 "UpdateDate": "2026-05-11T10:26:43.315Z"
}
```

## Using mc command (minio client) to create user "backup" on MinIO and attach policy
```bash
mc admin user add minio-admin backup backup123
Added user `backup` successfully.

mc admin policy attach minio-admin backup-custom-policy --user backup
Attached Policies: [backup-custom-policy]
To User: backup

mc admin user ls minio-admin
enabled    backup                backup-custom-policy
enabled    loki                  loki-custom-policy

```
## Using mc command 


## Apply backup daily schedule
```bash
kubectl apply -f pg-backup-daily.yaml

kubectl get scheduledbackup -n demo

NAME              AGE   CLUSTER      LAST BACKUP
pg-backup-daily   6s    pg-cluster
```

## Apply backup now to make sure barman work fine with MinIO
```bash
kubectl apply -f pg-backup-now.yaml
kubectl get backup -n demo

NAME            AGE   CLUSTER      METHOD              PHASE       ERROR
pg-backup-now   7s    pg-cluster   barmanObjectStore   completed
```

<img width="2553" height="1391" alt="attach5" src="https://github.com/user-attachments/assets/1ece130f-0fcb-47f3-9b22-66f816a62357" />
