#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
SK8S_VERSION=$(determine_sk8s_version "$build_root/git-sk8s" "$build_root/sk8s-version")

function update_values_tag(){
  local source_file="$1"
  local image_name="$2"
  local new_tag="$3"
  local tempfile="/tmp/tempvalues.yml"
  cat "$source_file" | tr '\n' '_' |  sed  -e "s#${image_name}_    tag: 0\.0\.1-SNAPSHOT#${image_name}_    tag: ${new_tag}#g"| tr '_' '\n' > "$tempfile"
  cp  "$tempfile" "$source_file"
}

pushd $build_root/git-sk8s/charts

  helm init --client-only

  update_values_tag "$build_root/git-sk8s/charts/sk8s/values.yaml" "function-controller"  "$SK8S_VERSION"
  update_values_tag "$build_root/git-sk8s/charts/sk8s/values.yaml" "zipkin-server"        "$SK8S_VERSION"

  topic_controller_version=$(head "$build_root/topic-controller-version/version")
  http_gw_version=$(head "$build_root/http-gateway-version/version")

  # Topic Controller and HTTP GW versions
  update_values_tag "$build_root/git-sk8s/charts/sk8s/values.yaml" "topic-controller"     "$topic_controller_version"
  update_values_tag "$build_root/git-sk8s/charts/sk8s/values.yaml" "http-gateway"         "$http_gw_version"

  # SIDECAR version
  export sidecar_version=$(head "$build_root/sidecar-version/version")
  tmp_fc_deploy="/tmp/tmp_fc_deploy"
  cat sk8s/templates/function-controller-deployment.yaml  | tr '\n' '#' | sed -e "s/env:/env:#          - name: SK8S_FUNCTION_CONTROLLER_SIDECAR_TAG#            value: ${sidecar_version}/g"  | tr '#' '\n' > "$tmp_fc_deploy"
  cp "$tmp_fc_deploy" sk8s/templates/function-controller-deployment.yaml

  chart_version=$(grep version sk8s/Chart.yaml  | awk '{print $2}')

  helm package sk8s --version "$chart_version"

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
