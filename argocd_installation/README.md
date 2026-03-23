# ArgoCD installation guide

#### Add repo
```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
```
#### Install ArgoCD
```bash
helm install argocd argo/argo-cd -n argocd --create-namespace
```
#### Install Cert-Manager
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.15.0/cert-manager.yaml
```
#### Create ClusterIssuer self-signed
```bash
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned
spec:
  selfSigned: {}
```
Apply:
```bash
kubectl apply -f issuer-selfsigned.yaml
```
#### Create cert.yaml self-signed
```bash
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: argocd-server-tls
  namespace: argocd
spec:
  secretName: argocd-server-tls
  dnsNames:
    - argocd.lab.local
  issuerRef:
    name: selfsigned
    kind: ClusterIssuer
```
Apply:
```bash
kubectl apply -f cert.yaml
```
#### Config ingress with TLS by update values.yaml
```bash
global:
  domain: argocd.lab.local
configs:
  params:
    server.insecure: true
server:
  ingress:
    enabled: true
    ingressClassName: nginx
    hosts:
      - host: argocd.lab.local
        paths:
          - path: /
            pathType: Prefix
    tls:
      - hosts:
          - argocd.lab.local
        secretName: argocd-server-tls
    annotations:
      cert-manager.io/cluster-issuer: selfsigned
      nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
      nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
```
Apply:
```bash
helm upgrade argocd argo/argo-cd -n argocd -f values.yaml
```
#### Check ArgoCD status:
Check:
```bash
kubectl get clusterissuer
```
Check Cert & Ingress status:
```bash
kubectl get certificate -n argocd
kubectl get ingress -n argocd
```
#### Workflow:
```
User
 ↓
Browser
 | (HTTP -> 301 -> HTTPS)							# force-ssl-redirect: "true"
 ↓ (HTTPS - port 443)							
NGINX Ingress (TLS terminate with cert "self-signed")
 ↓ (HTTP - port 80, internal cluster communication)				# backend-protocol: "HTTP" 
ArgoCD Server 
(Accept traffic HTTP)								# server.insecure: true			

#### Get admin secret and access the web UI 
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -oyaml | grep "password" | awk '{print $2}' | base64 -d ; echo
```
