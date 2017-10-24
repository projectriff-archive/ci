FROM jpetazzo/dind
ENV DOCKER_DAEMON_ARGS="--storage-driver vfs"
COPY start_docker.sh /usr/local/bin/start_docker
RUN add-apt-repository ppa:openjdk-r/ppa
RUN apt-get update
RUN apt-get install -y openjdk-8-jdk
RUN apt-get install -y maven
