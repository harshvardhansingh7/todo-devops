FROM jenkins/jenkins:lts-jdk17

USER root

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Docker CLI, git, curl, unzip
RUN apt-get update && apt-get install -y docker.io git curl unzip && rm -rf /var/lib/apt/lists/*

USER jenkins
WORKDIR /var/jenkins_home
