# CloudNativePG (cnpg operator) with Object Storage (MinIO)

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

## Deployment:

#### Build MinIO (s3 compatible storage)
```bash
kubectl apply -f deploy-minio.yaml
```

#### Apply CloudNativePG cluster
```bash
kubectl apply -f cluster-cnpg.yaml
```

#### Apply backup daily schedule
```bash
kubectl apply -f pg-backup-daily.yaml
```

