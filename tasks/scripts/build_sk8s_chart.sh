#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
SK8S_VERSION=$(determine_sk8s_version "$build_root/git-sk8s" "$build_root/sk8s-version")

pushd $build_root/git-sk8s/charts

  helm init --client-only

  HELM_VALUES_OVERRIDE=""
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}eventDispatcher.image.repository=sk8s/event-dispatcher,"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}eventDispatcher.image.tag=${SK8S_VERSION},"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}eventDispatcher.sidecarImage.repository=sk8s/function-sidecar,"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}eventDispatcher.sidecarImage.tag=${SK8S_VERSION},"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicController.image.repository=sk8s/topic-controller,"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicController.image.tag=${SK8S_VERSION},"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicGateway.image.repository=sk8s/topic-gateway,"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicGateway.image.tag=${SK8S_VERSION},"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicGateway.service.type=LoadBalancer,"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}zipkin.image.repository=sk8s/zipkin-server,"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}zipkin.image.tag=${SK8S_VERSION}"
  HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE},create.faas=true,create.crd=true,enable.tracingDashboard=true"

  temp_chart_dir=$(mktemp -d)
  mkdir -p "$temp_chart_dir/sk8s"

  cp sk8s/Chart.yaml "$temp_chart_dir/sk8s/"
  cp sk8s/values.yaml "$temp_chart_dir/sk8s/"
  mkdir "$temp_chart_dir/sk8s/templates"

  helm template "$temp_chart_dir/sk8s" --set "${HELM_VALUES_OVERRIDE}" > "$temp_chart_dir/sk8s/templates/all.yaml"

  helm package "$temp_chart_dir/sk8s" --version="$SK8S_VERSION"

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
