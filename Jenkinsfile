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
        # We will set KUBECONFIG dynamically to a temp copy inside steps
    }

    stages {
        stage('Checkout') {
            steps {
                git url: 'https://github.com/harshvardhansingh7/todo-devops.git', branch: 'main'
            }
        }

        stage('Build Maven Project') {
            steps { sh 'mvn clean package -DskipTests' }
        }

        stage('Build Docker Image') {
            steps { sh "docker build -t ${IMAGE_NAME} ." }
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

        stage('Prepare kubeconfig (safe)') {
            steps {
                sh '''
          # Ensure kubectl is available
          if ! command -v kubectl &> /dev/null; then
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
          fi

          # Check mounted kubeconfig exists (mounted read-only)
          if [ ! -f /root/.kube/config ]; then
            echo "ERROR: /root/.kube/config not found. Make sure you mounted your host kubeconfig into the container."
            exit 1
          fi

          # Create a writable temporary copy
          TMP_KUBECONFIG=/tmp/kubeconfig.$(date +%s)
          cp /root/.kube/config "$TMP_KUBECONFIG"

          # Determine current server URL (e.g. https://127.0.0.1:57778 or https://localhost:6443)
          SERVER_URL=$(kubectl --kubeconfig="$TMP_KUBECONFIG" config view -o=jsonpath='{.clusters[0].cluster.server}')
          echo "Original server URL: $SERVER_URL"

          # If server points to localhost / 127.0.0.1, rewrite to host.docker.internal:6443 (hostPort created by kind-config)
          # Use host.docker.internal so containers can reach the host port.
          if echo "$SERVER_URL" | grep -E '127\\.0\\.0\\.1|localhost' >/dev/null; then
            # Use port 6443 (our kind config mapped hostPort 6443)
            NEW_SERVER="https://host.docker.internal:6443"
            echo "Rewriting server to: $NEW_SERVER"
            # Replace server line in kubeconfig
            kubectl --kubeconfig="$TMP_KUBECONFIG" config set-cluster $(kubectl --kubeconfig="$TMP_KUBECONFIG" config get-clusters | head -n1) --server="$NEW_SERVER" --insecure-skip-tls-verify=true
          else
            echo "Server does not point to localhost; leaving as-is."
          fi

          # Export temp kubeconfig for rest of pipeline
          export KUBECONFIG="$TMP_KUBECONFIG"
          echo "Using temp kubeconfig: $KUBECONFIG"
          kubectl cluster-info || true
          kubectl get nodes || true

          # Persist KUBECONFIG in environment for later stages in this shell (we re-export in later stages)
          echo "KUBECONFIG=$KUBECONFIG" > /tmp/kubeenv
        '''
            }
        }

        stage('Test Kubernetes Access') {
            steps {
                sh '''
          source /tmp/kubeenv || true
          export KUBECONFIG=${KUBECONFIG:-/tmp/kubeconfig}
          echo "Testing access using temp kubeconfig..."
          kubectl cluster-info
          kubectl get nodes
        '''
            }
        }

        stage('Deploy to KIND') {
            steps {
                sh '''
          source /tmp/kubeenv || true
          export KUBECONFIG=${KUBECONFIG:-/tmp/kubeconfig}
          echo "Deploying to KIND cluster..."

          # Apply MySQL first (k8s manifests in repo)
          kubectl apply -f k8s/mysql.yaml
          kubectl wait --for=condition=ready pod -l app=mysql --timeout=300s || echo "mysql wait timed out"

          # Apply app manifests
          kubectl apply -f k8s/
          
          # If KIND cannot pull images from Docker Hub (rate-limit/credentials), you could instead:
          # kind load docker-image ${IMAGE_NAME} --name kind

          kubectl set image deployment/todo-app todo-app=${IMAGE_NAME} || true
          kubectl rollout status deployment/todo-app --timeout=300s || echo "rollout check finished"
        '''
            }
        }
    }

    post {
        always {
            sh '''
        source /tmp/kubeenv || true
        export KUBECONFIG=${KUBECONFIG:-/tmp/kubeconfig}
        echo "=== PODS ==="
        kubectl get pods -o wide || true
        echo "=== SERVICES ==="
        kubectl get svc || true
      '''
        }
        success { sh 'echo "Pipeline executed successfully!"' }
        failure { sh 'echo "Pipeline failed!"' }
    }
}
