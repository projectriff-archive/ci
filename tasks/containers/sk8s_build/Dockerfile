FROM jpetazzo/dind
ENV DOCKER_DAEMON_ARGS="--storage-driver vfs"
COPY start_docker.sh /usr/local/bin/start_docker
RUN add-apt-repository ppa:openjdk-r/ppa
RUN apt-get update
RUN apt-get install -y openjdk-8-jdk
RUN apt-get install -y maven
RUN curl -O https://storage.googleapis.com/kubernetes-release/release/v1.6.1/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin/kubectl
RUN apt-get install -y jq
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
