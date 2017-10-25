#!/bin/bash

set -exuo pipefail

build_root=$PWD

mkdir -p ~/.m2

cp -r "$build_root/m2-repo/repository" ~/.m2/

pushd $build_root/git-sk8s
  ./mvnw clean package -Ddocker.skip=true
  cp -r $build_root/git-sk8s/* "$build_root/sk8s-docker-contexts/"
popd
