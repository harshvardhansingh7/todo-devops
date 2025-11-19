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

        stage('Fix KIND kubeconfig') {
            steps {
                sh '''
                    # Make sure kubectl exists
                    if ! command -v kubectl &> /dev/null; then
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                    fi

                    echo "Rewriting kubeconfig for KIND inside Docker..."

                    # Replace localhost endpoints (127.0.0.1) with kind-control-plane
                    sed -i 's/127.0.0.1:[0-9]*/kind-control-plane:6443/g' /root/.kube/config
                '''
            }
        }

        stage('Test Kubernetes Access') {
            steps {
                sh '''
                    export KUBECONFIG=/root/.kube/config
                    echo "Checking connection to KIND cluster..."
                    kubectl cluster-info
                    kubectl get nodes
                '''
            }
        }

        stage('Deploy to KIND') {
            steps {
                sh '''
                    export KUBECONFIG=/root/.kube/config
                    echo "Deploying to KIND..."

                    # Apply MySQL first
                    kubectl apply -f k8s/mysql.yaml
                    kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s

                    # Apply app manifests
                    kubectl apply -f k8s/
                    kubectl set image deployment/todo-app todo-app=${IMAGE_NAME}
                    kubectl rollout status deployment/todo-app --timeout=300s

                    echo "Deployment completed successfully!"
                '''
            }
        }
    }

    post {
        always {
            sh '''
                export KUBECONFIG=/root/.kube/config
                kubectl get pods -o wide
                kubectl get svc
            '''
        }
    }
}
