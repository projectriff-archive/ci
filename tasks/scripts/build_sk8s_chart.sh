#!/bin/bash

set -exuo pipefail

build_root=$PWD
SK8S_VERSION=$(head "$build_root/sk8s-version/version")

pushd $build_root/git-sk8s/charts

  helm init --client-only

  helm package sk8s --version="$SK8S_VERSION"

  chart_file=$(basename sk8s*tgz)

  cp "$chart_file" "$build_root/sk8s-charts/"

  helm repo index "$build_root/sk8s-charts" --url "$SK8S_CHARTS_URL"

popd
