#!/bin/bash

/usr/local/bin/dockerd-entrypoint.sh 2>&1 &
until docker info >/dev/null 2>&1; do
  echo waiting for docker to come up...
  sleep 1
done
