#!/bin/bash

zookeeper-server-start.sh /kafka/config/zookeeper.properties > /var/log/zookeeper.log &
sleep 5
kafka-server-start.sh /kafka/config/server.properties > /var/log/kafka.log &
