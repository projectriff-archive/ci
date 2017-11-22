#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
init_kubeconfig

RIFF_VERSION=$(head "$build_root/gcs-riff-chart-latest-version/latest_version")

timestamp=$(date "+%s")

tiller_ns_name=$(generate_tiller_ns_name "$RIFF_VERSION" "$timestamp")
sk8s_ns_name=$(generate_riff_ns_name "$RIFF_VERSION" "$timestamp")
helm_release_name="${sk8s_ns_name}"

kubectl create ns "$tiller_ns_name"
kubectl create ns "$sk8s_ns_name"

helm init --tiller-namespace="$tiller_ns_name"

set +e
for i in {1..50}; do
  kubectl get pod -n "$tiller_ns_name" | grep Running | grep '1/1'
  if [ $? -eq 0 ]; then
      break
  fi
  sleep 5
done
set -e

# clear out existing CRDs; safe to do in non-prod
kubectl get customresourcedefinitions --all-namespaces -o json |
  jq -r  .items[].metadata.name |
  xargs -I{} kubectl delete customresourcedefinition {}

# deploy previously constructed helm chart
helm repo add riffrepo "$SK8S_CHARTS_URL"
helm repo update riffrepo
helm search riff

RND_HTTP_GW_EXTPORT=$(( ( RANDOM % 1000 )  + 40000 ))
ZIPKIN_EXTPORT=$(( ( RANDOM % 1000 )  + 40000 ))
DEPLOY_SK8S_OVERRIDE="httpGateway.service.externalPort=${RND_HTTP_GW_EXTPORT},zipkin.service.externalPort=${ZIPKIN_EXTPORT}"

chart_version_actual=$(helm inspect riffrepo/riff | grep version | awk '{print $2}')

curl -sL "${SK8S_CHARTS_URL}/riff-${chart_version_actual}-install-example.sh" > chart_install.sh
chmod +x  chart_install.sh
./chart_install.sh "riffrepo/riff" \
  --tiller-namespace="$tiller_ns_name" \
  --namespace="$sk8s_ns_name" \
  --name="$helm_release_name" \
  --set "${DEPLOY_SK8S_OVERRIDE}"

set +e
for i in {1..50}; do
  kubectl get pod -n "$sk8s_ns_name" | grep http-gateway | grep Running | grep '1/1'
  if [ $? -eq 0 ]; then
      break
  fi
  sleep 5
done
set -e
