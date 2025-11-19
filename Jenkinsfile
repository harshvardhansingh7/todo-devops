pipeline {
    agent any

    tools {
        maven 'maven'
        dockerTool 'docker'
    }

    environment {
        APP_NAME = 'todo-app'
        IMAGE_NAME = "harshvardhansingh7/todo-app:${env.BUILD_NUMBER}"
        DOCKER_HOST = "unix:///var/run/docker.sock"
        FIXED_KUBECONFIG = "/tmp/kubeconfig.kind"
        KIND_API_SERVER = "https://kind-control-plane:6443"
        KUBEENV_FILE = "/tmp/kubeenv"
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
                    sh '''
                        docker login -u "$USER" -p "$PASS"
                        docker push ${IMAGE_NAME}
                    '''
                }
            }
        }

        stage('Fix Kubeconfig') {
            steps {
                sh '''
            if [ ! -f /root/.kube/config ]; then
              echo "MISSING kubeconfig"
              exit 1
            fi

            cp /root/.kube/config ${FIXED_KUBECONFIG}
            chmod 600 ${FIXED_KUBECONFIG}

            # Replace localhost with KIND control-plane
            sed -i 's/https:\\/\\/localhost:6443/https:\\/\\/kind-control-plane:6443/g' ${FIXED_KUBECONFIG}
            sed -i 's/https:\\/\\/127.0.0.1:6443/https:\\/\\/kind-control-plane:6443/g' ${FIXED_KUBECONFIG}

            echo "export KUBECONFIG=${FIXED_KUBECONFIG}" > /tmp/kubeenv
        '''
            }
        }


        stage('Test Kubernetes Access') {
            steps {
                sh '''
                    . ${KUBEENV_FILE}
                    kubectl cluster-info
                    kubectl get nodes
                '''
            }
        }

        stage('Deploy to KIND') {
            steps {
                sh '''
                    . ${KUBEENV_FILE}

                    kubectl apply -f k8s/mysql.yaml
                    kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s || true

                    kubectl apply -f k8s/
                    kubectl set image deployment/todo-app todo-app=${IMAGE_NAME}
                    kubectl rollout status deployment/todo-app --timeout=300s || true
                '''
            }
        }
    }

    post {
        always {
            sh '''
                . ${KUBEENV_FILE} || true
                kubectl get pods -o wide || true
                kubectl get svc || true
            '''
        }
        success { sh 'echo "Pipeline executed successfully!"' }
        failure { sh 'echo "Pipeline failed!"' }
    }
}
