# Jenkins pipeline with ArgoCD + ImageUpdater

## Workflow:
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
## Install Argocd Image Updater from helm
```bash
helm install argocd-image-updater argo/argocd-image-updater  --namespace argocd
```
## Prepare codes following Helm structure

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
## Add secret on K8s for pulling image (namespace appteam1)
```bash
kubectl create secret docker-registry regcred \
  --docker-server=https://login.docker.com/ \
  --docker-username=<username> \
  --docker-password=<token-read-write-execution> \
  --docker-email=<email> \
  -n appteam1
```
## Add secret on K8s for "ArgoCD Image Updater" watching new tag version on Dockerhub:
```bash
kubectl create secret docker-registry regcred-ro \
  --docker-server=https://login.docker.com/ \
  --docker-username=<username> \
  --docker-password=<token-readonly-execution> \
  --docker-email=<email> \
  -n argocd
```
## Add secret on K8s for "ArgoCD Image Updater" update tag version on GitOps Repo (CD-Repo)
```bash
kubectl create secret generic regcred-gitops-repo \
  --from-literal=username=<your-github-username> \
  --from-literal=token=<your-github-personal-access-token> \
  -n argocd
```
## Connect CD-Repo on ArgoCD web UI

### Create a key-pair
```bash
ssh-keygen -t ed25519 -f argocd-github

ls | grep argocd-github
argocd-github
argocd-github.pub
```
### Copy "argocd-github.pub" to GitHub Repo
```bash
Select "CD-Repo" -> Settings -> Deploy keys -> Add deploy key:
- Title: "ArgoCD auth"
- Key: "ssh-ed25519 ... "
- Allow write access: "Enabled"
```
### Copy "argocd-github" to "SSH private key data":
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
## Create application for metrics-app and client-app
```bash
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: client-app
  namespace: argocd
  annotations:
    # Enable image updater for this application
    argocd-image-updater.argoproj.io/image-list: clientapp=peidhhn/client-app
    argocd-image-updater.argoproj.io/clientapp.pull-secret: argocd/regcred-ro
    # Update strategy: use the latest semver tag
    argocd-image-updater.argoproj.io/clientapp.update-strategy: semver
    # Ignore specific tag
    argocd-image-updater.argoproj.io/clientapp.ignore-tags: "latest"
    # Only consider tags matching this regex
    argocd-image-updater.argoproj.io/clientapp.allow-tags: regexp:^v[0-9]+-[0-9]+-[a-f0-9]+$
    # Updat if using helm values path
    argocd-image-updater.argoproj.io/clientapp.helm.image-name: image.repository
    argocd-image-updater.argoproj.io/clientapp.helm.image-tag: image.tag
    # Write back method: git
    argocd-image-updater.argoproj.io/write-back-method: git
    argocd-image-updater.argoproj.io/git-secret: argocd/regcred-gitops-repo
    # Branch to write updates to
    argocd-image-updater.argoproj.io/git-branch: main
    # Custom commit message
    argocd-image-updater.argoproj.io/git-commit-message: |
      chore: update image {{range .Updated}}{{.Name}}={{.NewTag}} {{end}}

      Signed-off-by: ArgoCD Image Updater

spec:
  project: default
  source:
    repoURL: git@github.com:Dnetdumb/CD-Repo.git
    targetRevision: main
    path: appteam1/helm/client-app
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

# Please implement the same for metrics-app
```
### Apply:
```bash
kubectl apply -f argo-client-app.yaml
kubectl apply -f argo-metrics-app.yaml
```
### Reference Source:
```bash
https://oneuptime.com/blog/post/2026-01-25-image-updater-argocd/view
```
### Check:
<img width="1268" height="1263" alt="image" src="https://github.com/user-attachments/assets/e87eb14d-823b-42e6-b44c-c8c3bfaad6a6" />

## Create imageupdater for metrics-app and client-app

```bash
apiVersion: argocd-image-updater.argoproj.io/v1alpha1
kind: ImageUpdater
metadata:
  name: client-app-updater
  namespace: argocd
spec:
  applicationRefs:
    - namePattern: "client-app"
      useAnnotations: true

#Please implement the same for metrics-app
```
### Apply:
```bash
kubectl apply -f client-app-updater.yaml
kubectl apply -f metrics-app-updater.yaml
```
## Demo full:
#### Jenkins webhook trigger when dev push code to run pipeline:
```bash
git add .
git commit -m "Feat: Trigger Jenkins Webhook with new build"
```

<img width="1257" height="527" alt="image" src="https://github.com/user-attachments/assets/47b96fa4-243b-46da-ba35-fd39261b80fd" />

#### Pipeline:

<img width="1269" height="1039" alt="image" src="https://github.com/user-attachments/assets/49084f91-4b44-4892-bee9-ca85e24baa54" />

#### Check DockerHub:

<img width="1266" height="569" alt="image" src="https://github.com/user-attachments/assets/ab813e78-88f6-4d49-abbb-4f2aaa2aee46" />

#### ArgoCD Image Updater update on GitOps Repo (CD-Repo):

<img width="1271" height="463" alt="image" src="https://github.com/user-attachments/assets/1245c8a1-0470-40b2-88fe-a7d26a71fd9d" />

<img width="1271" height="806" alt="image" src="https://github.com/user-attachments/assets/68593eea-86a7-4fbf-93f0-60c4ef419daf" />

<img width="1265" height="703" alt="image" src="https://github.com/user-attachments/assets/77858085-9757-4ba1-ba4b-99d5ac9e977e" />

#### ArgoCD detect and sync deploy to K8s:

<img width="1263" height="705" alt="image" src="https://github.com/user-attachments/assets/48a29864-a0fc-4f83-947f-910772bb92d2" />

<img width="1270" height="723" alt="image" src="https://github.com/user-attachments/assets/c0b35cff-32ea-4149-9720-abd7169152f6" />
