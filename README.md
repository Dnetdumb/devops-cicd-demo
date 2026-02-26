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


2. On Github Repo
   |__Create repo "devops-cicd-demo" 
      |__Push source app onto repo
      |__Update Dockerfile
      |__Update Jenkinsfile


4. On Jenkins Server
   |__Create project "devops-cicd-demo"
   |__

<img width="831" height="859" alt="image" src="https://github.com/user-attachments/assets/723bdfee-7b0f-48de-a05a-8a20982e316e" />




