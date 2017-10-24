#!/bin/bash

set -exuo pipefail

build_root=$PWD

mkdir -p ~/.m2

cp -r "$build_root/m2-repo/repository" ~/.m2/

cd $build_root/git-sk8s

set +u
source /opt/resource/common.sh
start_docker 

./mvnw clean package
./dockerize
set -u

mkdir ~/.kube
echo "$KUBECONFIG_STRING" > ~/.kube/config

set +e
existing_ns=$(kubectl get ns -o json | jq -r  .items[].metadata.name | grep "$K8S_NS_PREFIX")

if [ ! -z "$existing_ns" ]; then
  kubectl delete ns "$existing_ns" --cascade=true
  sleep 30
fi
set -e

ns_suffix=$(date "+%s")
ns_name="$K8S_NS_PREFIX"-"$ns_suffix"

kubectl create ns "$ns_name"
kubectl apply -f config/types -n "$ns_name"
kubectl apply -f config/kafka -n "$ns_name"
kubectl apply -f config -n "$ns_name"

cp $build_root/git-sk8s/function-invokers/java-function-invoker/target/java-function-invoker*.jar "$build_root/sk8s-invoker-java/"
