#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
init_kubeconfig

RIFF_NAME=$(head "$build_root/gcs-riff-chart-latest-name/latest_name")
RIFF_VERSION=$(head "$build_root/gcs-riff-chart-latest-version/latest_version")

# delete existing tiller deployment
existing_tiller_ns_name=$(find_existing_tiller_ns "$RIFF_NAME" "$RIFF_VERSION")
if [ ! -z "$existing_tiller_ns_name" ]; then
  set +e
  helm ls  --tiller-namespace="$existing_tiller_ns_name" | grep -v NAME | awk '{print $1}' | xargs -I{} helm  --tiller-namespace="$existing_tiller_ns_name" delete {} --purge
  set -e
fi

# delete existing tiller and helm namespaces
existing_riff_ns_name=$(find_existing_riff_ns "$RIFF_NAME" "$RIFF_VERSION")
set +e
echo "$existing_riff_ns_name" | xargs -I{} kubectl delete ns {} --cascade=true
echo "$existing_tiller_ns_name" | xargs -I{} kubectl delete ns {} --cascade=true
set -e

kubectl get customresourcedefinitions --all-namespaces -o json |
  jq -r  .items[].metadata.name |
  xargs -I{} kubectl delete customresourcedefinition {}
