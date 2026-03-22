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
        secretName: argocd-tls
    annotations:
      cert-manager.io/cluster-issuer: selfsigned
```
Apply:
```bash
helm upgrade argocd argo/argo-cd -n argocd -f values.yaml
```
#### Check ArgoCD status
Check:
```bash
kubectl get clusterissuer
```
Check Cert & Ingress status:
```bash
kubectl get certificate -n argocd
kubectl get ingress -n argocd
```

