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
                      bash -lc '
                      docker login -u "$USER" -p "$PASS"
                      docker push ${IMAGE_NAME}
                      '
                    '''
                }
            }
        }

        stage('Prepare kubeconfig (safe)') {
            steps {
                sh '''
                  bash -lc '
                  set -e

                  # ensure kubectl exists
                  if ! command -v kubectl &> /dev/null; then
                    echo "Installing kubectl..."
                    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                    rm kubectl
                  fi

                  # check mounted kubeconfig
                  if [ ! -f /root/.kube/config ]; then
                    echo "ERROR: /root/.kube/config not found. Make sure you mounted your host kubeconfig into the container."
                    exit 1
                  fi

                  # create writable temp copy
                  TMP_KUBECONFIG=/tmp/kubeconfig.$(date +%s)
                  cp /root/.kube/config "$TMP_KUBECONFIG"
                  chmod 600 "$TMP_KUBECONFIG"

                  # get current server URL (client-side only)
                  SERVER_URL=$(/usr/local/bin/kubectl --kubeconfig="$TMP_KUBECONFIG" config view -o=jsonpath="{.clusters[0].cluster.server}")
                  echo "Original server URL: $SERVER_URL"

                  # if it points to localhost/127.0.0.1, rewrite to host.docker.internal:6443
                  if echo "$SERVER_URL" | grep -E "127\\.0\\.0\\.1|localhost" >/dev/null; then
                    NEW_SERVER="https://host.docker.internal:6443"
                    echo "Rewriting server to: $NEW_SERVER"
                    CLUSTER_NAME=$(/usr/local/bin/kubectl --kubeconfig="$TMP_KUBECONFIG" config get-clusters | head -n1)
                    /usr/local/bin/kubectl --kubeconfig="$TMP_KUBECONFIG" config set-cluster "$CLUSTER_NAME" --server="$NEW_SERVER" --insecure-skip-tls-verify=true
                  else
                    echo "Server does not point to localhost; leaving as-is."
                  fi

                  export KUBECONFIG="$TMP_KUBECONFIG"
                  echo "export KUBECONFIG=$TMP_KUBECONFIG" > /tmp/kubeenv
                  echo "Using temp kubeconfig: $KUBECONFIG"
                  /usr/local/bin/kubectl --kubeconfig="$KUBECONFIG" cluster-info || true
                  /usr/local/bin/kubectl --kubeconfig="$KUBECONFIG" get nodes || true
                  '
                '''
            }
        }

        stage('Test Kubernetes Access') {
            steps {
                sh '''
                  bash -lc '
                  # load KUBECONFIG exported by previous step
                  if [ -f /tmp/kubeenv ]; then
                    source /tmp/kubeenv
                  fi
                  echo "Testing access using KUBECONFIG=${KUBECONFIG:-/tmp/kubeconfig}"
                  /usr/local/bin/kubectl --kubeconfig="${KUBECONFIG:-/tmp/kubeconfig}" cluster-info
                  /usr/local/bin/kubectl --kubeconfig="${KUBECONFIG:-/tmp/kubeconfig}" get nodes
                  '
                '''
            }
        }

        stage('Deploy to KIND') {
            steps {
                sh '''
                  bash -lc '
                  if [ -f /tmp/kubeenv ]; then
                    source /tmp/kubeenv
                  fi
                  echo "Deploying to KIND cluster using KUBECONFIG=${KUBECONFIG:-/tmp/kubeconfig}"

                  # Apply MySQL first (k8s manifests in repo)
                  /usr/local/bin/kubectl --kubeconfig="${KUBECONFIG:-/tmp/kubeconfig}" apply -f k8s/mysql.yaml
                  /usr/local/bin/kubectl --kubeconfig="${KUBECONFIG:-/tmp/kubeconfig}" wait --for=condition=ready pod -l app=mysql --timeout=300s || echo "mysql wait timed out"

                  # Apply app manifests
                  /usr/local/bin/kubectl --kubeconfig="${KUBECONFIG:-/tmp/kubeconfig}" apply -f k8s/

                  # Update image (if deployment exists)
                  /usr/local/bin/kubectl --kubeconfig="${KUBECONFIG:-/tmp/kubeconfig}" set image deployment/todo-app todo-app=${IMAGE_NAME} || true
                  /usr/local/bin/kubectl --kubeconfig="${KUBECONFIG:-/tmp/kubeconfig}" rollout status deployment/todo-app --timeout=300s || echo "rollout check finished"
                  '
                '''
            }
        }
    }

    post {
        always {
            sh '''
              bash -lc '
              if [ -f /tmp/kubeenv ]; then
                source /tmp/kubeenv
              fi
              KCFG=${KUBECONFIG:-/tmp/kubeconfig}
              echo "=== PODS ==="
              /usr/local/bin/kubectl --kubeconfig="$KCFG" get pods -o wide || true
              echo "=== SERVICES ==="
              /usr/local/bin/kubectl --kubeconfig="$KCFG" get svc || true
              '
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
