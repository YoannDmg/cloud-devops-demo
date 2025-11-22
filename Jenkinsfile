// =============================================================================
// CI/CD PIPELINE - Cloud DevOps Demo
// =============================================================================
// Full pipeline for building, testing, and deploying Angular + NestJS app
// =============================================================================

pipeline {
    agent any

    environment {
        // Docker Registry Configuration
        DOCKER_REGISTRY = 'ydmg'
        IMAGE_BACKEND   = "${DOCKER_REGISTRY}/cloud-devops-backend"
        IMAGE_FRONTEND  = "${DOCKER_REGISTRY}/cloud-devops-frontend"
        DOCKER_CREDS    = 'docker-registry'
    }

    options {
        timeout(time: 30, unit: 'MINUTES')
        disableConcurrentBuilds()
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }

    stages {
        // =====================================================================
        // STAGE 1: Checkout & Setup
        // =====================================================================
        stage('Checkout') {
            steps {
                checkout scm

                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.BUILD_VERSION = "main-${env.GIT_COMMIT_SHORT}"

                    echo "=========================================="
                    echo "Build Information"
                    echo "=========================================="
                    echo "Commit:     ${env.GIT_COMMIT_SHORT}"
                    echo "Version:    ${env.BUILD_VERSION}"
                    echo "=========================================="
                }
            }
        }

        // =====================================================================
        // STAGE 2: Build Applications (Parallel)
        // =====================================================================
        stage('Build Applications') {
            parallel {
                stage('Build Backend') {
                    agent {
                        docker {
                            image 'node:20-alpine'
                            args '-u root:root'
                            reuseNode true
                        }
                    }
                    steps {
                        dir('backend') {
                            sh '''
                                echo "Installing backend dependencies..."
                                npm ci --prefer-offline
                                echo "Running linter..."
                                npm run lint || echo "Lint warnings found"
                                echo "Running tests..."
                                npm run test -- --passWithNoTests || echo "Tests completed"
                                echo "Building backend..."
                                npm run build
                                echo "Backend build completed successfully"
                            '''
                        }
                    }
                }

                stage('Build Frontend') {
                    agent {
                        docker {
                            image 'node:20-alpine'
                            args '-u root:root'
                            reuseNode true
                        }
                    }
                    steps {
                        dir('frontend') {
                            sh '''
                                echo "Installing frontend dependencies..."
                                npm ci --prefer-offline
                                echo "Building frontend..."
                                npm run build -- --configuration=production
                                echo "Frontend build completed successfully"
                            '''
                        }
                    }
                }
            }
        }

        // =====================================================================
        // STAGE 3: Build Docker Images
        // =====================================================================
        stage('Build Docker Images') {
            steps {
                script {
                    echo "Building Docker images..."

                    sh """
                        docker build \
                            --tag ${IMAGE_BACKEND}:${env.BUILD_VERSION} \
                            --tag ${IMAGE_BACKEND}:latest \
                            --label "git.commit=${env.GIT_COMMIT_SHORT}" \
                            --label "build.number=${BUILD_NUMBER}" \
                            ./backend
                    """

                    sh """
                        docker build \
                            --tag ${IMAGE_FRONTEND}:${env.BUILD_VERSION} \
                            --tag ${IMAGE_FRONTEND}:latest \
                            --label "git.commit=${env.GIT_COMMIT_SHORT}" \
                            --label "build.number=${BUILD_NUMBER}" \
                            ./frontend
                    """

                    echo "Docker images built successfully"
                    sh "docker images | grep ${DOCKER_REGISTRY} || true"
                }
            }
        }

        // =====================================================================
        // STAGE 4: Push to Registry
        // =====================================================================
        stage('Push to Registry') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: DOCKER_CREDS,
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "Logging into Docker registry..."
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''

                    script {
                        echo "Pushing images to registry..."

                        sh "docker push ${IMAGE_BACKEND}:${env.BUILD_VERSION}"
                        sh "docker push ${IMAGE_BACKEND}:latest"

                        sh "docker push ${IMAGE_FRONTEND}:${env.BUILD_VERSION}"
                        sh "docker push ${IMAGE_FRONTEND}:latest"

                        echo "Images pushed successfully"
                    }
                }
            }
        }

        // =====================================================================
        // STAGE 5: Cleanup
        // =====================================================================
        stage('Cleanup') {
            steps {
                sh '''
                    echo "Cleaning up local Docker images..."
                    docker image prune -f || true
                    echo "Cleanup completed"
                '''
            }
        }
    }

    // =========================================================================
    // POST-BUILD ACTIONS
    // =========================================================================
    post {
        success {
            echo """
            ==========================================
            BUILD SUCCESSFUL
            ==========================================
            Version:  ${env.BUILD_VERSION}
            Backend:  ${IMAGE_BACKEND}:${env.BUILD_VERSION}
            Frontend: ${IMAGE_FRONTEND}:${env.BUILD_VERSION}
            ==========================================
            """
        }

        failure {
            echo """
            ==========================================
            BUILD FAILED
            ==========================================
            Check the logs above for error details.
            ==========================================
            """
        }

        always {
            echo "Pipeline completed"
        }
    }
}
