#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
SK8S_VERSION=$(determine_sk8s_version "$build_root/git-sk8s" "$build_root/sk8s-version")

pushd $build_root/git-sk8s/charts

  helm init --client-only

  helm package sk8s --version="$SK8S_VERSION"

  chart_file=$(basename sk8s*tgz)

  cp "$chart_file" "$build_root/sk8s-charts/"

  set +e
  curl -sfL "$SK8S_CHARTS_URL/index.yaml" > existing_index.yaml
  if [ "0" != "$?" ]; then
    rm -f existing_index.yaml
  fi
  set -e

  if [ -f existing_index.yaml ]; then
    helm repo index "$build_root/sk8s-charts" --url "$SK8S_CHARTS_URL" --merge existing_index.yaml
  else
    helm repo index "$build_root/sk8s-charts" --url "$SK8S_CHARTS_URL"
  fi

popd
