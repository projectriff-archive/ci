#!/bin/bash

set -exuo pipefail

build_root=$PWD

cd $build_root/git-sk8s

pushd charts
  helm package sk8s
  # TODO: push chart to helm repo
popd

mkdir ~/.kube
echo "$KUBECONFIG_STRING" > ~/.kube/config

existing_tiller_ns_name=$(kubectl get ns | grep "$K8S_NS_PREFIX-tiller")
if [ ! -z "$existing_tiller_ns_name" ]; then
  helm ls  --tiller-namespace="$existing_tiller_ns_name" | grep -v NAME | awk '{print $1}' | xargs -I{} helm  --tiller-namespace="$existing_tiller_ns_name" delete {} --purge
fi

kubectl get ns -o json | jq -r  .items[].metadata.name | grep "$K8S_NS_PREFIX" | xargs -I{} kubectl delete ns {} --cascade=true
sleep 30

ns_suffix=$(date "+%s")
tiller_ns_name="$K8S_NS_PREFIX"-tiller-"$ns_suffix"
sk8s_ns_name="$K8S_NS_PREFIX"-sk8s-"$ns_suffix"
helm_release_name="sk8s-$ns_suffix"

kubectl create ns "$tiller_ns_name"
kubectl create ns "$sk8s_ns_name"

helm init --tiller-namespace="$tiller_ns_name"

# clear out existing CRDs; safe to do in non-prod
kubectl get customresourcedefinitions --all-namespaces -o json |
  jq -r  .items[].metadata.name |
  xargs -I{} kubectl delete customresourcedefinition {}

pushd charts
    chart_file=$(basename sk8s*tgz)
    helm install "$chart_file" \
      --tiller-namespace="$tiller_ns_name" \
      --namespace="$sk8s_ns_name" \
      --name="$helm_release_name" \
      --set create.faas=true,create.crd=true
popd
