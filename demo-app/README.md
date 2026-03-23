# Full Demo

## Idea:

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
#### Build and Run the Main App (`metrics-app`)
Build the Docker image and push it to Docker Hub
```bash
docker build -t peidhhn/metrics-app:latest -f Dockerfile.main .
docker push -t peidhhn/metrics-app:latest
```

#### Deploy the Main App
Deploy it to the namespace `appteam1`:
```
kubectl apply -f main.deployment.yaml -n appteam1 --create-namspace
```

#### Build and Run the Client App
Build docker image and push to docker hub
```bash
docker build -t peidhhn/client-app:latest -f Dockerfile.client .
docker push -t peidhhn/client-app:latest
```

#### Deploy the Client App
Deploy it to the same namespace `appteam1`
```bash 
kubectl apply -f client.deployment.yaml -n appteam1 --create-namespace
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

## Jenkins pipeline with ArgoCD

### Workflow:

Checkout Code
      │
      ▼
Build Docker Images
      │
      ▼
Trivy security scan     ← Optional
      │
      ▼
Push DockerHub
      │
      ▼
Manual Approval
      │
      ▼
Update K8s Manifest (new image tag)
      │
      ▼
Push Manifest to Git (CD-Repo)
      │
      ▼
ArgoCD Sync (auto/manual)
      │
      ▼
Deploy Kubernetes (ArgoCD handle)
      │
      ▼
Verify Rollout
      │
      ▼
Endpoint Test
      │
      ▼
Pipeline Success

### First, push code, connect "CD-Repo" and create an application on ArgoCD web UI

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
#### Connect CD-Repo
First: Create a key-pair 
```bash
ssh-keygen -t ed25519 -f argocd-github

ls | grep argocd-github
argocd-github
argocd-github.pub
```
Copy "argocd-github.pub" to GitHub Repo
```bash
Select "CD-Repo" -> Settings -> Deploy keys -> Add deploy key:
- Title: "ArgoCD auth"
- Key: "ssh-ed25519 ... "
- Allow write access: "Enabled"
```
Copy "argocd-github" to "SSH private key data":
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
#### Create application.yaml cho metrics-app và client-app
```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: metrics-app | client-app
  namespace: argocd
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
kubectl apply -f argo-client-app.yaml -n argocd
kubectl apply -f argo-metrics-app.yaml -n argocd
```
#### Reconfigure "Script Path" and add new github-token for CD-Repo
```bash
Script Path: "demo-app/Jenkinsfile_update_ArgoCD"

Manage Jenkins
→ Credentials
→ Global
→ Add Credentials
  → Kind: Username + Password
  → ID: github-CD-Repo
  → Password: ghp_xxxxxx
```

