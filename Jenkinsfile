pipeline {

    agent { label 'docker' }

    environment {
        IMAGE_BACKEND  = "ydmg/cloud-devops-backend"
        IMAGE_FRONTEND = "ydmg/cloud-devops-frontend"
        DOCKER_CREDS   = "docker-registry"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Backend') {
            agent {
                docker { 
                    image 'node:20-alpine'
                    args '-u root:root'
                }
            }
            steps {
                sh """
                cd backend
                npm install
                npm run build
                """
            }
        }

        stage('Build Frontend') {
            agent {
                docker { 
                    image 'node:20-alpine'
                    args '-u root:root'
                }
            }
            steps {
                sh """
                cd frontend
                npm install
                npm run build --prod
                """
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(credentialsId: DOCKER_CREDS,
                                                 usernameVariable: 'USER',
                                                 passwordVariable: 'PASS')]) {
                    sh '''
                        echo "$PASS" | docker login -u "$USER" --password-stdin
                    '''
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh "docker build -t ${IMAGE_BACKEND}:latest ./backend"
                sh "docker build -t ${IMAGE_FRONTEND}:latest ./frontend"
            }
        }

        stage('Push Images') {
            steps {
                sh "docker push ${IMAGE_BACKEND}:latest"
                sh "docker push ${IMAGE_FRONTEND}:latest"
            }
        }
    }

    post {
        always {
            echo "Pipeline completed."
        }
    }
}
