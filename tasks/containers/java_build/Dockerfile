FROM openjdk:8
ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH=$GOROOT/bin:$PATH
RUN apt-get update && \
  apt-get install -y make wget && \
  wget https://storage.googleapis.com/golang/go1.5.linux-amd64.tar.gz && \
  tar -C /usr/local -xzf go1.5.linux-amd64.tar.gz
