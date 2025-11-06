pipeline {
    agent any

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
                sh 'docker build -t todo-app .'
            }
        }

        stage('Run Docker Container') {
            steps {
                sh 'docker run -d -p 8081:8080 --name todo-app todo-app || true'
            }
        }
    }
}
