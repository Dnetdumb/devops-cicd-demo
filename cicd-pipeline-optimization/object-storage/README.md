# MinIO (Object Storage)

## Deployment:

### Apply MinIO secret (admin)
```bash
kubectl apply -f minio-secret.yaml
```
### Apply pv (Persistent Volume) for MinIO
```bash
kubectl apply -f pv-minio.yaml

# Verify:
kubectl get pv -n demo

NAME       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM               STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pv-minio   10Gi        RWO            Retain           Available   demo/data-minio-0   manual         <unset>                          12s
```

### Install MinIO from YAML file
```bash
kubectl apply -f minio.yaml

statefulset.apps/minio created
service/svc-minio created
ingress.networking.k8s.io/ingress-minio created

# Verify:
kubectl get sts,svc,ingress,pods -n demo -owide

NAME                     READY   AGE     CONTAINERS   IMAGES
statefulset.apps/minio   1/1     3m27s   minio        quay.io/minio/minio:latest

NAME                TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)             AGE     SELECTOR
service/svc-minio   ClusterIP   10.103.182.122   <none>        9000/TCP,9001/TCP   3m27s   app=minio

NAME                                      CLASS   HOSTS             ADDRESS         PORTS   AGE
ingress.networking.k8s.io/ingress-minio   nginx   minio.lab.local   192.168.1.253   80      3m27s

NAME          READY   STATUS    RESTARTS   AGE     IP                NODE           NOMINATED NODE   READINESS GATES
pod/minio-0   1/1     Running   0          3m27s   192.168.180.198   worker-node1   <none>           <none>
```
### Add an Alias with mc command (minio client) to manage minIO from command line
```bash
mc alias set minio-admin http://192.168.180.198:9000 minio minio123
```

### Login web UI on "http://minio.lab.local" with credentials "minio-secret"

attach1.png

attach2.png
