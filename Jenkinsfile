pipeline {
    agent any
    
    environment {
            IMAGE_NAME = "peidhhn/devops-web-lab"
    }
    
    stages { 
        
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Docker Build') {
            steps {
                 script {
                    app = docker.build("${IMAGE_NAME}:${env.BUILD_NUMBER}")
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                script {
                    docker.withRegisTry('https://hub.docker.com/','docker_hub_id')
                    app.push("$env.BUILD_NUMBER")
                    app.push("latest")
                }
            }
        }
        stage('Run Container') {
            steps {
                sh '''
                docker stop devops-container || true
                docker rm devops-container || true
                docker run -d -p 8082:80 --name devops-container $app
                '''
            }
        }
    }
}
