pipeline {
    agent any

    tools {
        maven 'maven'
        dockerTool 'docker'
    }

    environment {
        APP_NAME = 'todo-app'
        IMAGE_NAME = "harshvardhansingh7/todo-app:${env.BUILD_NUMBER}"
        KUBECONFIG = "/root/.kube/config"
        DOCKER_HOST = "unix:///var/run/docker.sock"
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

        stage('Setup Kubernetes Access') {
            steps {
                sh '''
                    # Install kubectl if not present
                    if ! command -v kubectl &> /dev/null; then
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                    fi

                    # Use the mounted kubeconfig
                    export KUBECONFIG=/root/.kube/config

                    echo "Testing Kubernetes connection..."
                    kubectl cluster-info
                    kubectl get nodes
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    export KUBECONFIG=/root/.kube/config
                    echo "Deploying to Docker Desktop Kubernetes..."

                    # Apply MySQL first
                    kubectl apply -f k8s/mysql.yaml
                    kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s

                    # Apply application deployment
                    kubectl apply -f k8s/
                    kubectl set image deployment/todo-app todo-app=${IMAGE_NAME}
                    kubectl rollout status deployment/todo-app --timeout=300s

                    echo "Deployment completed successfully!"
                """
            }
        }
    }

    post {
        always {
            sh '''
                export KUBECONFIG=/root/.kube/config
                echo "Cleaning up..."
                kubectl get pods -o wide
                kubectl get services
            '''
        }
        success {
            sh 'echo "Pipeline executed successfully!"'
        }
        failure {
            sh 'echo "Pipeline failed!"'
        }
    }
}
