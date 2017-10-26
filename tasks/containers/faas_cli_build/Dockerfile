FROM jpetazzo/dind
ENV DOCKER_DAEMON_ARGS="--data-root /scratch"
COPY start_docker.sh /usr/local/bin/start_docker
RUN add-apt-repository ppa:openjdk-r/ppa && \
  apt-get update && \
  apt-get install -y openjdk-8-jdk maven jq
RUN KUBERNETES_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin/kubectl
ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH=$GOROOT/bin:$PATH
RUN wget https://storage.googleapis.com/golang/go1.9.linux-amd64.tar.gz && \
  tar -C /usr/local -xzf go1.9.linux-amd64.tar.gz
RUN wget https://github.com/golang/dep/releases/download/v0.3.2/dep-linux-amd64 && \
  mv dep-linux-amd64 /usr/local/bin/dep && \
  chmod +x /usr/local/bin/dep
RUN go get github.com/maxbrunsfeld/counterfeiter && \
  cp /root/go/bin/counterfeiter  /usr/local/bin/
