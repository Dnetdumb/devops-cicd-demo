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
