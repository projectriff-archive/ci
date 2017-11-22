#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
init_kubeconfig

SK8S_VERSION=$(head "$build_root/gcs-riff-chart-latest-version/latest_version")

# delete existing tiller deployment
existing_tiller_ns_name=$(find_existing_tiller_ns "$SK8S_VERSION")
if [ ! -z "$existing_tiller_ns_name" ]; then
  set +e
  helm ls  --tiller-namespace="$existing_tiller_ns_name" | grep -v NAME | awk '{print $1}' | xargs -I{} helm  --tiller-namespace="$existing_tiller_ns_name" delete {} --purge
  set -e
fi

# delete existing tiller and sk8s namespaces
existing_sk8s_ns_name=$(find_existing_sk8s_ns "$SK8S_VERSION")
set +e
echo "$existing_sk8s_ns_name" | xargs -I{} kubectl delete ns {} --cascade=true
echo "$existing_tiller_ns_name" | xargs -I{} kubectl delete ns {} --cascade=true
set -e

kubectl get customresourcedefinitions --all-namespaces -o json |
  jq -r  .items[].metadata.name |
  xargs -I{} kubectl delete customresourcedefinition {}
