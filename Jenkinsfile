pipeline {
    agent any

    environment {
        APP_NAME = 'todo-app'
        IMAGE_NAME = "harshvardhansingh7/todo-app:${env.BUILD_NUMBER}"
        DEPLOYMENT_YAML = 'todo-deployment.yaml'
        KUBE_NAMESPACE = 'default'
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
                        echo "$PASS" | docker login -u "$USER" --password-stdin
                        docker push ${IMAGE_NAME}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    # Replace the image in deployment YAML
                    sed -i 's|image: .*|image: ${IMAGE_NAME}|' ${DEPLOYMENT_YAML}

                    # Apply deployment & service
                    kubectl apply -f ${DEPLOYMENT_YAML} -n ${KUBE_NAMESPACE}

                    # Wait for rollout
                    kubectl rollout status deployment/${APP_NAME} -n ${KUBE_NAMESPACE}
                """
            }
        }
    }
}
