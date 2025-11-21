pipeline {
    agent any

    environment {
        REGISTRY       = "docker.io"
        IMAGE_BACKEND  = "ydmg/cloud-devops-backend"
        IMAGE_FRONTEND = "ydmg/cloud-devops-frontend"
        DOCKER_CREDS   = "docker-registry"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/**TON_REPO_ICI**.git'
            }
        }

        stage('Build Backend') {
            steps {
                dir('backend') {
                    sh 'npm install'
                    sh 'npm run build || true'
                }
            }
        }

        stage('Build Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'npm run build --prod || true'
                }
            }
        }

        stage('Docker Login') {
            steps {
                script {
                    withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDS}",
                                                     usernameVariable: 'DOCKER_USER',
                                                     passwordVariable: 'DOCKER_PASS')]) {
                        sh """
                           echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                        """
                    }
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                script {
                    sh "docker build -t ${IMAGE_BACKEND}:latest ./backend"
                    sh "docker build -t ${IMAGE_FRONTEND}:latest ./frontend"
                }
            }
        }

        stage('Push Images') {
            steps {
                script {
                    sh "docker push ${IMAGE_BACKEND}:latest"
                    sh "docker push ${IMAGE_FRONTEND}:latest"
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh "docker system prune -f || true"
            }
        }
    }

    post {
        always {
            echo "Pipeline finished."
        }
    }
}
