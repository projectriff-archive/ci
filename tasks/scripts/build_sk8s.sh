#!/bin/bash

set -exuo pipefail

build_root=$PWD
model_dir="$(go env GOPATH)/src/github.com/fabric8io"
mkdir -p $model_dir
cp -r $build_root/git-kubernetes-model $model_dir/kubernetes-model
cd $model_dir/kubernetes-model
make
cd $build_root/git-sk8s
./mvnw clean package -Ddocker.skip=true

cp $build_root/git-sk8s/function-invokers/java-function-invoker/target/java-function-invoker*.jar "$build_root/sk8s-invoker-java/"
