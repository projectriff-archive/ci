FROM docker
ENV DOCKER_DAEMON_ARGS="--data-root /scratch"
COPY start_docker.sh /usr/local/bin/start_docker
RUN apk update && \
  apk add \
    bash \
    openjdk8 \
    alpine-sdk \
    maven \
    jq \
    go

RUN KUBERNETES_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
  curl -LO https://storage.googleapis.com/kubernetes-release/release/$KUBERNETES_VERSION/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin/kubectl

RUN wget https://github.com/golang/dep/releases/download/v0.3.2/dep-linux-amd64 && \
  mv dep-linux-amd64 /usr/local/bin/dep && \
  chmod +x /usr/local/bin/dep

RUN go get github.com/maxbrunsfeld/counterfeiter && \
  cp /root/go/bin/counterfeiter  /usr/local/bin/
