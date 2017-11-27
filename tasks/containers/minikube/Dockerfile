FROM ubuntu:trusty
RUN apt-get update && \
  apt-get install -y wget curl git && \
  curl -fsSL get.docker.com | bash
ENV CHANGE_MINIKUBE_NONE_USER=true
RUN wget "https://storage.googleapis.com/kubernetes-release/release/v1.8.0/bin/linux/amd64/kubectl" -O "/usr/local/bin/kubectl" && \
  chmod +x /usr/local/bin/kubectl && \
  wget "https://storage.googleapis.com/minikube/releases/v0.23.0/minikube-linux-amd64" -O "/usr/local/bin/minikube" && \
  chmod +x /usr/local/bin/minikube
RUN minikube start --vm-driver none --kubernetes-version v1.8.0
