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

<img width="831" height="859" alt="image" src="https://github.com/user-attachments/assets/723bdfee-7b0f-48de-a05a-8a20982e316e" />

- Configure GitHub Integration:

Generate new token: Personal access tokens (classic) on github and add credentials with this token on Jenkins server

<img width="1251" height="276" alt="image" src="https://github.com/user-attachments/assets/0805e56f-6990-4224-90e1-416f5b59772d" />


- Configure DockerHub Integration:

Generate new token: Personal access tokens on docker hub and add credentials with this token on Jenkins server

<img width="960" height="203" alt="image" src="https://github.com/user-attachments/assets/9230b105-ecda-4594-a371-4099ff25fcc8" />


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

- DEMO: ...

<img width="1272" height="416" alt="image" src="https://github.com/user-attachments/assets/e40e328e-3fba-4b8b-b859-dc659605cd52" />


<img width="1272" height="747" alt="image" src="https://github.com/user-attachments/assets/e6f49e3d-24f7-4a05-8529-9a93960d6f25" />



