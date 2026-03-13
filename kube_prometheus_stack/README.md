# Installation guide kube-prometheus-stack 

## Add Helm Repo
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```
## First, install MetalLB + Ingress-nginx
Add manifest:
```bash
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
```
Check:
```bash
kubectl get pods -n metallb-system

NAME                          READY   STATUS    RESTARTS   AGE
controller-56bb48dcd4-k5fzp   1/1     Running   0          7m30s
speaker-b9wm5                 1/1     Running   0          7m30s
speaker-s49d2                 1/1     Running   0          7m30s
speaker-vchpb                 1/1     Running   0          7m30s
```
Configure MetalLB IP Pool:
```bash
sudo touch metallb-config.yaml

apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lab-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.253-192.168.1.253		# This ip is VIP (Virtual IP) and will be update in DNS record /etc/hosts
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: lab-advert
  namespace: metallb-system
```
Apply:
```bash
kubectl apply -f metallb-config.yaml
```
Install ingress-nginx
```bash
helm install ingress-nginx ingress-nginx/ingress-nginx --namespace ingress-nginx --set controller.service.type=LoadBalancer --create-namespace
```
Verify VIP assignment:
```bash
kubectl get svc -n ingress-nginx
NAME                                 TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                      AGE
ingress-nginx-controller             LoadBalancer   10.102.124.74   192.168.1.253   80:31661/TCP,443:31885/TCP   72s
ingress-nginx-controller-admission   ClusterIP      10.107.75.254   <none>          443/TCP                      72s
```
## Verify kube-prometheus-stack repo
```bash
helm search repo kube-prometheus-stack
```
## Install kube-prometheus-stack with namespace "monitoring" and custom file "values.yaml"
```bash
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f values.yaml --create-namespace
```
Check:
```bash
kubectl get ingress -n monitoring

NAME                                      CLASS   HOSTS                  ADDRESS         PORTS   AGE
prometheus-grafana                        nginx   grafana.lab.local      192.168.1.253   80      3m58s
prometheus-kube-prometheus-alertmanager   nginx   alert.lab.local        192.168.1.253   80      3m58s
prometheus-kube-prometheus-prometheus     nginx   prometheus.lab.local   192.168.1.253   80      3m58s
```
## Scale up deployment ingress-nginx replicas to 2
Currently, Worker-Node1 is assigned to keep VIP: 192.168.1.253
```bash
kubectl get pods -n ingress-nginx -owide

NAME                                        READY   STATUS    RESTARTS   AGE   IP                NODE           NOMINATED NODE   READINESS GATES
ingress-nginx-controller-85c495dcd4-6nb29   1/1     Running   0          33m   192.168.180.194   worker-node1   <none>           <none>
```
If Worker-Node1 down, ingress will not work because no pod left handle traffic:
```bash
kubectl scale deploy ingress-nginx-controller -n ingress-nginx --replicas=2
```
## Final, update the DNS record (/etc/hosts) and access the browser
```bash
192.168.1.253	prometheus.lab.local
192.168.1.253   alert.lab.local
192.168.1.253   metrics-app.lab.local
```
<img width="2558" height="1385" alt="image" src="https://github.com/user-attachments/assets/e91860ef-ff66-4e1a-ada9-de9901d2a69d" />

Credentials to login grafana:

```bash
# User: admin
# Password:
kubectl get secrets prometheus-grafana -n monitoring -oyaml | grep -e "admin-password" | awk '{print $2}' | base64 -d
```
