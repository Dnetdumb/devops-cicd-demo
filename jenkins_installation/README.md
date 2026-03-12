# Jenkins Installation Guide

## Install Java
```bash
sudo apt update
sudo apt install fontconfig openjdk-21-jre
```
## Add Jenkins Repository

#### Import Jenkins GPG key:
```bash
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \ 
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
```
#### Add Jenkins repository:
```bash
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list
```
## Update package and install Jenkins
```bash
sudo apt update
sudo apt install -y jenkins
```
## Start Jenkins
```bash
sudo systemctl enable jenkins
sudo systemctl start jenkins
```
## Allow port 8080 
```bash
ufw allow 8080
```
## Access Jenkins web UI
Open browser:
```bash
http://192.168.1.200:8080
```
Get initial admin password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```
## Install docker
```bash
sudo apt install -y docker.io
```
## Install Plugins on web UI
```bash
Pipeline		#Core
Git
Credentials Binding
Kubernetes
Kubernetes CLI
Docker Pipeline 	#Optional
```
## Install kubectl
```bash
sudo snap install kubectl --classic
```
## Add credentials to Jenkins
Get GitHub Personal Access Token:
```bash
Settings
→ Developer Settings
→ Personal access tokens
→ Tokens (classic)
→ Generate token
 → Copy the token
```
Add credentials with this token to Jenkins:
```bash
Manage Jenkins
→ Credentials
→ Global
→ Add Credentials
  → Kind: Secret text
  → ID: github-token
  → Secret: ghp_xxxxxx
```
On Master Node:
```bash
cat ~/.kube/config    # Copy file kubeconfig
```
Add kubernetes credential with kubeconfig to Jenkins:
```bash
Manage Jenkins
→ Credentials
→ Global
→ Add Credentials
  → Kind: Secret file
  → ID: kubeconfig
  → file: kubeconfig
```
Add Docker registry credential to Jenkins:
```bash
Manage Jenkins
→ Credentials
→ Global
→ Add Credentials
  → Kind: Username + Password
  → ID: docker-hub
```
<img width="1266" height="402" alt="image" src="https://github.com/user-attachments/assets/368f2657-c424-4489-a3a9-aa8bfedf0faf" />

## Add a project to Jenkins

<img width="1277" height="326" alt="image" src="https://github.com/user-attachments/assets/9ae32905-a305-4ff5-b2ed-97530f995a66" />

Turn on trigger GitHub Webhook:

<img width="907" height="291" alt="image" src="https://github.com/user-attachments/assets/8b0c992f-eefc-4010-900d-15e377ce9c33" />

Change Pipeline Definition:







