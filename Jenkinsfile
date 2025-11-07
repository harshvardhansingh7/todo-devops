pipeline {
    agent any

    environment {
        APP_NAME = 'todo-app'
        IMAGE_NAME = "harshvardhansingh7/todo-app:${env.BUILD_NUMBER}" // full Docker Hub image path
        KUBE_NAMESPACE = 'default' // Kubernetes namespace
        DEPLOYMENT_YAML = 'todo-app-deployment.yaml'  // root folder
        SERVICE_YAML = 'todo-app-service.yaml'        // root folder
    }

    stages {

        stage('Checkout') {
            steps {
                git url: 'https://github.com/harshvardhansingh7/todo-devops.git', branch: 'main'
            }
        }

        stage('Build with Maven') {
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
                        echo $PASS | docker login -u $USER --password-stdin
                        docker push ${IMAGE_NAME}
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    # Update deployment YAML with new image
                    sed -i 's|image: .*|image: ${IMAGE_NAME}|' ${DEPLOYMENT_YAML}

                    # Apply deployment and service
                    kubectl apply -f ${DEPLOYMENT_YAML} -n ${KUBE_NAMESPACE}
                    kubectl apply -f ${SERVICE_YAML} -n ${KUBE_NAMESPACE}

                    # Optional: wait for rollout
                    kubectl rollout status deployment/${APP_NAME} -n ${KUBE_NAMESPACE}
                """
            }
        }
    }
}
