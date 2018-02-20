FROM instrumentisto/dep

RUN apt-get update && \
  apt-get install -yy \
    bash \
    jq

RUN KUBERNETES_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin/kubectl
