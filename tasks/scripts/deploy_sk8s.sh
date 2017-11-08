#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
SK8S_VERSION=$(determine_sk8s_version "$build_root/git-sk8s" "$build_root/sk8s-version")

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

mkdir ~/.kube
echo "$KUBECONFIG_STRING" > ~/.kube/config

timestamp=$(date "+%s")

tiller_ns_name=$(generate_tiller_ns_name "$K8S_NS_PREFIX" "$SK8S_VERSION" "$timestamp")
sk8s_ns_name=$(generate_sk8s_ns_name "$K8S_NS_PREFIX" "$SK8S_VERSION" "$timestamp")
helm_release_name="${sk8s_ns_name}"

kubectl create ns "$tiller_ns_name"
kubectl create ns "$sk8s_ns_name"

helm init --tiller-namespace="$tiller_ns_name"
sleep 15 # wait for helm to be ready

# clear out existing CRDs; safe to do in non-prod
kubectl get customresourcedefinitions --all-namespaces -o json |
  jq -r  .items[].metadata.name |
  xargs -I{} kubectl delete customresourcedefinition {}

# deploy previously constructed helm chart
helm repo add sk8srepo "$SK8S_CHARTS_URL"
helm repo update sk8srepo
helm search sk8s

helm install "sk8srepo/sk8s" \
  --tiller-namespace="$tiller_ns_name" \
  --namespace="$sk8s_ns_name" \
  --name="$helm_release_name" \
  --version="${SK8S_VERSION}" \
  --set "${HELM_VALUES_OVERRIDE},create.faas=true,create.crd=true,enable.tracingDashboard=true"
