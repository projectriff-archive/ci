FROM alpine
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
  apk update && \
  apk add bash openjdk8 alpine-sdk python go && \
  wget https://archive.apache.org/dist/kafka/0.11.0.1/kafka_2.11-0.11.0.1.tgz && \
  tar -xzf kafka* && \
  rm kafka*.tgz && \
  mv kafka*/ kafka/ && \
  wget https://github.com/edenhill/kafkacat/archive/1.3.1.tar.gz && \
  tar -xzf 1.3.1.tar.gz && \
  cd kafkacat-1.3.1 && ./bootstrap.sh && \
  mv kafkacat /usr/local/bin
ENV PATH=$PATH:/kafka/bin
COPY start_kafka.sh /kafka/bin/start_kafka
RUN chmod +x /kafka/bin/start_kafka
RUN wget https://github.com/golang/dep/releases/download/v0.3.2/dep-linux-amd64 && \
  mv dep-linux-amd64 /usr/local/bin/dep && \
  chmod +x /usr/local/bin/dep
RUN wget https://github.com/Masterminds/glide/releases/download/v0.13.1/glide-v0.13.1-linux-amd64.tar.gz && \
  tar xvzf glide-v0.13.1-linux-amd64.tar.gz && \
  mv linux-amd64/glide /usr/local/bin/glide && \
  chmod +x /usr/local/bin/glide
