#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
SK8S_VERSION=$(determine_sk8s_version "$build_root/git-sk8s" "$build_root/sk8s-version")

mkdir -p ~/.m2

cp -r "$build_root/m2-repo/repository" ~/.m2/

pushd $build_root/git-sk8s
  ./mvnw versions:set -DnewVersion="$SK8S_VERSION"
  ./mvnw clean package -Ddocker.skip=true
  cp -r $build_root/git-sk8s/* "$build_root/sk8s-docker-contexts/"
  echo "$SK8S_VERSION" > "$build_root/sk8s-docker-contexts/sk8s_version"
popd
