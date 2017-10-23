#!/bin/bash

set -exuo pipefail

build_root=$PWD

model_dir="$(go env GOPATH)/src/github.com/fabric8io"
mkdir -p $model_dir
cp -r $build_root/git-kubernetes-model $model_dir/kubernetes-model
cd $model_dir/kubernetes-model

make

cp -r ~/.m2/repository "$build_root/m2-repo/"
