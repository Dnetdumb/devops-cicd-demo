**Jenkins CI/CD with GitHub Integration**


Scenery:

Local Ubuntu VM
│
├── Docker
│   └── Jenkins (containerized)
│
├── GitHub Repo
│
├── Jenkins Pipeline (Jenkinsfile)
│
├── Dockerized App


1. On local VM (Ubuntu Server 22.04)
   
- Install Docker:

apt install docker.io

- Create a Dockerfile to build jenkins server:

FROM jenkins/jenkins:lts

USER root

RUN apt update && \
    apt install -y docker.io && \
    apt clean

USER jenkins

- Build:

docker build -t jenkins-docker .

<img width="583" height="62" alt="image" src="https://github.com/user-attachments/assets/264b6b62-6059-4dff-9cb2-3cc187043ea0" />

- Start container from based image:

<img width="611" height="141" alt="image" src="https://github.com/user-attachments/assets/1cebcc49-1468-42bb-a46d-e8b1ff7b6175" />

- Do command line "cat /var/jenkins_home/secrets/initialAdminPassword" to login and first setup for jenkins

<img width="693" height="42" alt="image" src="https://github.com/user-attachments/assets/89236e0d-15e2-47fb-940a-80de493eea28" />

<img width="999" height="431" alt="image" src="https://github.com/user-attachments/assets/38e61230-b41c-4078-af24-c6ff10b5355f" />


- Open Jenkins: http://URL:8080

- Create a New Jenkins Project "devops-cicd-demo"

- Configure GitHub Integration:

Under Source Code Management, select Git and enter your GitHub repository URL.

Generate new token: Personal access tokens (classic) on github and add credentials with this token on Jenkins server

- Configure Build Triggers:

Check GitHub hook trigger for GITScm polling.

2. On Github Repo

- Create project "devops-cicd-demo"
- Push source app onto repo
- Update Dockerfile
- Update Jenkinsfile


- Add Webhook:

Payload URL: http://URL:8080/github-webhook/

Content Type: application/json

<img width="831" height="859" alt="image" src="https://github.com/user-attachments/assets/723bdfee-7b0f-48de-a05a-8a20982e316e" />






