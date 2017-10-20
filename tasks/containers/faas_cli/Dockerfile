FROM concourse/docker-image-resource
RUN apk update && \
  apk add alpine-sdk bash wget go git
RUN wget https://github.com/golang/dep/releases/download/v0.3.2/dep-linux-amd64 && \
  mv dep-linux-amd64 /usr/local/bin/dep && \
  chmod +x /usr/local/bin/dep
RUN go get github.com/maxbrunsfeld/counterfeiter && \
  cp /root/go/bin/counterfeiter  /usr/local/bin/
ENV GOPATH=/root/go
