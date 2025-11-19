FROM jenkins/jenkins:lts-jdk17

USER root
WORKDIR /tmp

# Install prerequisites, kubectl and Docker CLI (stable)
RUN apt-get update \
  && apt-get install -y ca-certificates curl gnupg lsb-release apt-transport-https unzip git \
  && curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/v1.30.0/bin/linux/amd64/kubectl" \
  && chmod +x /usr/local/bin/kubectl \
  # Install docker (cli) from distro package (docker.io) - ok for CI usage
  && apt-get install -y docker.io \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/*

# (Optional) Verify versions at build time (helpful in logs)
RUN kubectl version --client --short || true \
  && docker --version || true \
  && git --version || true

# Return to the jenkins user (the container will run as root per docker-compose, but leaving Jenkins user set is fine)
USER jenkins
WORKDIR /var/jenkins_home

# keep default Jenkins image entrypoint/cmd
