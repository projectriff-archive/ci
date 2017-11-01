FROM alpine
RUN echo "http://dl-6.alpinelinux.org/alpine/edge/community" > /etc/apk/repositories && \
  apk update && \
  apk add bash openjdk8 alpine-sdk python go && \
  wget http://www-us.apache.org/dist/kafka/0.10.2.0/kafka_2.10-0.10.2.0.tgz && \
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
