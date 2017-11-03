#!/bin/bash

set -exuo pipefail

build_root=$PWD
SK8S_VERSION=$(head "$build_root/sk8s-version/version")

HELM_VALUES_OVERRIDE=""
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}eventDispatcher.image.repository=sk8s/event-dispatcher,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}eventDispatcher.image.tag=latest,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicController.image.repository=sk8s/topic-controller,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicController.image.tag=latest,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicGateway.image.repository=sk8s/topic-gateway,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicGateway.image.tag=latest,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicGateway.service.type=LoadBalancer,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}zipkin.image.repository=sk8s/zipkin-server,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}zipkin.image.tag=latest"

mkdir ~/.kube
echo "$KUBECONFIG_STRING" > ~/.kube/config

# delete existing tiller deployments
set +e
existing_tiller_ns_name=$(kubectl get ns | grep "$K8S_NS_PREFIX-tiller" | awk '{print $1}')
if [ ! -z "$existing_tiller_ns_name" ]; then
  helm ls  --tiller-namespace="$existing_tiller_ns_name" | grep -v NAME | awk '{print $1}' | xargs -I{} helm  --tiller-namespace="$existing_tiller_ns_name" delete {} --purge
fi
set -e

# delete existing CI namespaces
set +e
kubectl get ns -o json | jq -r  .items[].metadata.name | grep "$K8S_NS_PREFIX" | xargs -I{} kubectl delete ns {} --cascade=true
set -e
sleep 30

sanitized_version=$(echo "$SK8S_VERSION" | sed 's/\./-/g' |  awk '{print tolower($0)}')
timestamp=$(date "+%s")
ns_suffix="${sanitized_version}-${timestamp}"
tiller_ns_name="$K8S_NS_PREFIX"-tiller-"$ns_suffix"
sk8s_ns_name="$K8S_NS_PREFIX"-sk8s-"$ns_suffix"
helm_release_name="sk8s-$ns_suffix"

kubectl create ns "$tiller_ns_name"
kubectl create ns "$sk8s_ns_name"

helm init --tiller-namespace="$tiller_ns_name"
sleep 15 # wait for helm to be ready

# clear out existing CRDs; safe to do in non-prod
kubectl get customresourcedefinitions --all-namespaces -o json |
  jq -r  .items[].metadata.name |
  xargs -I{} kubectl delete customresourcedefinition {}

# deploy previously constructed helm chart
helm repo add sk8srepo https://sk8s_charts_dev.storage.googleapis.com
helm repo update sk8srepo
helm search sk8s

helm install "sk8srepo/sk8s" \
  --tiller-namespace="$tiller_ns_name" \
  --namespace="$sk8s_ns_name" \
  --name="$helm_release_name" \
  --set "${HELM_VALUES_OVERRIDE},create.faas=true,create.crd=true,enable.tracingDashboard=true"
