pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                sh 'docker build -t devops-lab-web:latest .'
            }
        }

        stage('Run Container') {
            steps {
                sh '''
                docker stop devops-container || true
                docker rm devops-container || true
                docker run -d -p 8082:80 --name devops-container devops-lab-web:latest
                '''
            }
        }
    }
}
