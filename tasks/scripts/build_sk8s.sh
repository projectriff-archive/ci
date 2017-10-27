#!/bin/bash

set -exuo pipefail

build_root=$PWD

SK8S_VERSION=$(head "$build_root/sk8s-version/version")

mkdir -p ~/.m2

cp -r "$build_root/m2-repo/repository" ~/.m2/

pushd $build_root/git-sk8s
  ./mvnw clean package -Ddocker.skip=true
  ./mvnw versions:set -DnewVersion="$SK8S_VERSION"
  cp -r $build_root/git-sk8s/* "$build_root/sk8s-docker-contexts/"
  echo "$SK8S_VERSION" > "$build_root/sk8s-docker-contexts/sk8s_version"
popd
