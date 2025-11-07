pipeline {
    agent any

    environment {
        APP_NAME = 'todo-app'
        APP_PORT = '8081'
        IMAGE_NAME = "todo-app:${env.BUILD_NUMBER}" // versioned Docker image
    }

    stages {

        stage('Checkout') {
            steps {
                // Pull latest code from GitHub
                git url: 'https://github.com/harshvardhansingh7/todo-devops.git', branch: 'main'
            }
        }

        stage('Build with Maven') {
            steps {
                // Compile and package the Spring Boot app
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('Build Docker Image') {
            steps {
                // Build Docker image and tag with build number
                sh "docker build -t ${IMAGE_NAME} ."
            }
        }

        stage('Stop Old Container') {
            steps {
                // Stop and remove old container if exists
                sh "docker rm -f ${APP_NAME} || true"
            }
        }

        stage('Run Docker Container') {
            steps {
                // Run new container on host port
                sh "docker run -d -p ${APP_PORT}:8080 --name ${APP_NAME} ${IMAGE_NAME}"
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                // Securely use Docker Hub credentials stored in Jenkins
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                        echo $PASS | docker login -u $USER --password-stdin
                        docker tag ${IMAGE_NAME} $USER/${APP_NAME}:${env.BUILD_NUMBER}
                        docker push $USER/${APP_NAME}:${env.BUILD_NUMBER}
                    """
                }
            }
        }
    }
}
