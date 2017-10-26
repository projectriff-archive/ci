FROM concourse/docker-image-resource
RUN apk update && \
  apk add alpine-sdk bash wget go git openjdk8 maven
RUN wget https://github.com/golang/dep/releases/download/v0.3.2/dep-linux-amd64 && \
  mv dep-linux-amd64 /usr/local/bin/dep && \
  chmod +x /usr/local/bin/dep
RUN go get github.com/maxbrunsfeld/counterfeiter && \
  cp /root/go/bin/counterfeiter  /usr/local/bin/
ENV GOPATH=/root/go

RUN KUBERNETES_VERSION=$(curl -s -k -L https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
  curl -L -k https://storage.googleapis.com/kubernetes-release/release/${KUBERNETES_VERSION}/bin/linux/amd64/kubectl > /usr/local/bin/kubectl && \
  chmod +x /usr/local/bin/kubectl

RUN curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash
