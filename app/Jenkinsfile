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
                withCredentials([usernamePassword(
                credentialsId: 'docker_hub_id',
                usernameVariable: 'DOCKER_USER',
                passwordVariable: 'DOCKER_PASS'
             )]) {

                        sh '''
                        echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                        docker push peidhhn/devops-web-lab:${BUILD_NUMBER}
                        '''
                }
            }
        }
        stage('Run Container') {
            steps {
                sh '''
                docker stop devops-container || true
                docker rm devops-container || true
                docker run -d -p 8082:80 --name devops-container ${IMAGE_NAME}:${BUILD_NUMBER}
                '''
            }
        }
    }
}
