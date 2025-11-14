pipeline {
    agent any

    tools {
        maven 'maven'
        dockerTool 'docker'
    }

    environment {
        APP_NAME = 'todo-app'
        IMAGE_NAME = "harshvardhansingh7/todo-app:${env.BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                git url: 'https://github.com/harshvardhansingh7/todo-devops.git', branch: 'main'
            }
        }

        stage('Build Maven Project') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                        docker login -u "$USER" -p "$PASS"
                        docker push ${IMAGE_NAME}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                // Ensure kubectl uses proper PATH and cluster context
                withEnv(["PATH+KUBECTL=/usr/local/bin"]) {
                    sh '''
                        echo "Deploying ${IMAGE_NAME} to Kubernetes..."
                        kubectl apply -f k8s/ --validate=false
                        kubectl set image deployment/todo-app todo-app=${IMAGE_NAME} || true
                        kubectl rollout status deployment/todo-app
                    '''
                }
            }
        }
    }
}
