# Full Demo

#### Brief:

The application metrics-app is the main service. It provides the following APIs:
```bash
/api/user
/api/order
/api/payment
```
Whenever requests are sent to these APIs, the application records:
```bash
Total number of requests
Response time
Response status
```
The application exposes metrics at the endpoint:
```bash
/metrics
```

#### Update "prometheusrule" for metrics-app 
```bash
kubectl apply -f prometheus-rule.yaml
```
Check:
```bash
get prometheusrule -n appteam1
NAME                AGE
metrics-app-rules   31s
```
<img width="2525" height="502" alt="image" src="https://github.com/user-attachments/assets/73f042cd-e631-4f7b-8294-25bef8d020b7" />

#### Create a Dashboard to Monitor Metrics
We can import the file "main.dashboard.exported.json" directly into Grafana to create a dashboard for monitoring the application's metrics.

<img width="2544" height="969" alt="image" src="https://github.com/user-attachments/assets/c74118d7-08e7-4c6c-a138-34b4c2edc753" />

## Config auto send slack message if match NAMESPACE with values.yaml
Create channel:
```bash
Create channel: 'alert-appteam1'
Create channel: 'alert-appteam2'
```
Install and config "incoming webhook"
```bash
Select "Edit settings" -> Intergation -> Add an app -> search "incoming webhook" and install -> Add to slack -> Post to channel "alert-team1" -> Copy "Webhook URL"
```
Update "channel" and "Webhook URL" to values.yaml 
```bash
 - name: "appteam2"
      slack_configs:
      - api_url: "$Webhook URL"
        channel: '#alert-appteam2'
...
- name: "appteam1"
      slack_configs:
      - api_url: "$Webhook URL"
        channel: '#alert-appteam1'
...
```
Upgrade helm:
```bash
helm upgrade prometheus prometheus-community/kube-prometheus-stack -n monitoring -f values.yaml --reuse-values
```

## Demo with Jenkinsfiles:

#### Jenkins Pipeline Flow:
```bash
Checkout Code
      │
      ▼
Build Docker Images
      │
      ▼
Trivy security scan	← Optional
      │
      ▼
Push DockerHub
      │
      ▼
Manual Approval
      │
      ▼
Deploy Kubernetes
      │
      ▼
Verify Rollout		← make sure pod running
      │
      ▼
Endpoint Test		← check service/pod
      │
      ▼
Pipeline Success
```

Check result:

<img width="2555" height="940" alt="image" src="https://github.com/user-attachments/assets/af2b71d8-436c-4b5c-ab69-dd8bc85c3f8f" />

<img width="2559" height="1087" alt="image" src="https://github.com/user-attachments/assets/cf930827-2558-4f43-9bbb-41f545de83d5" />

7<img width="1853" height="765" alt="image" src="https://github.com/user-attachments/assets/d483b8af-0fac-43d4-9080-77e1035fb537" />

<img width="2476" height="814" alt="image" src="https://github.com/user-attachments/assets/00f95304-1e3e-4156-93e1-09581bb40bee" />

<img width="2557" height="990" alt="image" src="https://github.com/user-attachments/assets/b870348c-5f0c-4fa0-a70a-17757549e3ea" />

## Jenkins pipeline with ArgoCD + ImageUpdater

### Workflow:
```bash
Dev push code
      │
      ▼
Jenkins (CI)
  - Checkout code
  - Build Docker images
  - Trivy scan
  - Push DockerHub
      │
      ▼
Image Registry (DockerHub)
      │
      ▼
ArgoCD Image Updater
  - Detect new tag version
  - Update Helm values on Git 
      │
      ▼
GitOps Repo (CD-Repo)
      │
      ▼
ArgoCD
  - Detect Git change
  - Auto sync
      │
      ▼
Deploy Kubernetes
      │
      ▼
Verify Rollout (ArgoCD UI / health)

Key Benefit: 
1. Enhance security from Jenkins impact on K8s 
2. GIT is Source of Truth
3. Easy Audit and rollback
4. Separate CI and CD
```
### Prepare codes following Helm structure

```bash
root@Master-CP1:/home/admin/CD-Repo/appteam1# pwd
/home/admin/CD-Repo/appteam1

root@Master-CP1:/home/admin/CD-Repo/appteam1# tree -L 3.
.
└── helm
    ├── client-app
    │   ├── charts
    │   ├── Chart.yaml
    │   ├── templates
    │   └── values.yaml
    └── metrics-app
        ├── charts
        ├── Chart.yaml
        ├── templates
        └── values.yaml

7 directories, 4 files
```
### Add secret on K8s for pulling image (namespace appteam1)
```bash
kubectl create secret docker-registry regcred \
  --docker-server=https://login.docker.com/ \
  --docker-username=<username> \
  --docker-password=<token-read-write-execution> \
  --docker-email=<email> \
  -n appteam1
```
### Add secret on K8s for "ArgoCD Image Updater" watching new tag version:
```bash
kubectl create secret docker-registry regcred_ro \
  --docker-server=https://login.docker.com/ \
  --docker-username=<username> \
  --docker-password=<token-readonly-execution> \
  --docker-email=<email> \
  -n appteam1
```
### Add secret on K8s for "ArgoCD Image Updater" update tag version on GitOps Repo (CD-Repo)
```bash
kubectl create secret generic regcred-gitops-repo \
  --from-literal=username=<your-github-username> \
  --from-literal=token=<your-github-personal-access-token> \
  -n appteam1
```
### Upgrade helm for "ArgoCD Image Updater" (configmap update)
```bash
helm upgrade argocd-image-updater argo/argocd-image-updater \
  --namespace argocd \
  --set config.git.username=<your-github-username> \
  --set config.git.token=<your-github-personal-access-token> \
  --set config.dockerRegistries[0].name=dockerhub \
  --set config.dockerRegistries[0].username=<dockerhub-username> \
  --set config.dockerRegistries[0].password=<dockerhub-token> \
  --set config.imagePullSecrets[0].name=regcred_ro \
  --set config.log.level=info
```
### Connect CD-Repo on ArgoCD web UI

#### Create a key-pair 
```bash
ssh-keygen -t ed25519 -f argocd-github

ls | grep argocd-github
argocd-github
argocd-github.pub
```
#### Copy "argocd-github.pub" to GitHub Repo
```bash
Select "CD-Repo" -> Settings -> Deploy keys -> Add deploy key:
- Title: "ArgoCD auth"
- Key: "ssh-ed25519 ... "
- Allow write access: "Enabled"
```
#### Copy "argocd-github" to "SSH private key data":
```bash
Settings -> Repositories -> + CONNECT REPO
- Connection method: "VIA SSH"
- Name: "CD-Repo"
- ProjectL :"default"
- Repository URL: "git@github.com:Dnetdumb/CD-Repo.git"
- SSH private key data: 
-----BEGIN OPENSSH PRIVATE KEY-----
...
-----END OPENSSH PRIVATE KEY-----
CONNECT 
```
### Create application.yaml cho metrics-app và client-app 
```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: metrics-app | client-app
  namespace: argocd
  annotations:
    argocd-image-updater.argoproj.io/image-list: metricsapp=peidhhn/metrics-app		| 	clientapp=peidhhn/client-app
    argocd-image-updater.argoproj.io/metricsapp.update.strategy: newest-build				
    argocd-image-updater.argoproj.io/metricsapp.allow-tags: regexp:^v[0-9]+-[0-9]+-[a-f0-9]+$
    argocd-image-updater.argoproj.io/metricsapp.write-back-method: git 
    argocd-image-updater.argoproj.io/metricsapp.helm.image-tag: image.tag
    argocd-image-updater.argoproj.io/metricsapp.write-back-method: git
    argocd-image-updater.argoproj.io/git-branch: main
spec:
  project: default
  source:
    repoURL: git@github.com:Dnetdumb/CD-Repo.git
    targetRevision: main
    path: appteam1/helm/metrics-app | appteam1/helm/client-app
    helm:
      valueFiles:
        - values.yaml

  destination:
    server: https://kubernetes.default.svc
    namespace: appteam1

  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```
Apply:
```bash
kubectl apply -f argo-client-app.yaml
kubectl apply -f argo-metrics-app.yaml


```
