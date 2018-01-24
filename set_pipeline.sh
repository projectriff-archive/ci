#!/bin/bash

set -e -o pipefail

[ -z "${DEBUG}" ] || set -x

set -u

ci_dir="$(cd "$(dirname "$0")"; pwd)"

print_usage() {
  echo "Usage:"
  echo "    $0 <pipeline name> [branch name] "
  echo ""
  echo "    valid pipeline names:"
  for name in ${ci_dir}/pipelines/*.yml; do
    local pipeline_name
    pipeline_name="$(basename "${name}")"
    echo "        - ${pipeline_name%.yml}"
  done
  echo
}

extract_pipeline_name() {
  local pipeline_name="$1"

  local pipeline_filename="${ci_dir}/pipelines/${pipeline_name}.yml"
  if [ ! -f "${pipeline_filename}" ]; then
    pipeline_filename="${ci_dir}/pipelines/${pipeline_name}"
    if [ ! -f "${pipeline_filename}" ]; then
      echo "Unknown pipeline name ${pipeline_name}"
      print_usage
      exit 1
    fi
  fi

  pipeline_name=$(basename "${pipeline_filename}")
  echo -n "${pipeline_name%.*}"
}

main() {
  local pipeline_name
  if [ "$#" == "0" ]; then
    print_usage
    exit 1
  fi
  pipeline_name=$(extract_pipeline_name "${1}")

  local pipeline_filename="${ci_dir}/pipelines/${pipeline_name}.yml"
  local branch_name="master"

  if [ -z  "$(which lpass)" ]; then
    echo "Unable to locate the LastPass CLI"
    print_usage
    exit 1
  fi

  echo "${pipeline_name}"
  local current_branch_regex='-current-branch$'
  if [[ "${pipeline_name}" =~ $current_branch_regex ]]; then
    branch_name="${2:-$branch_name}"
    git_username=$(git config user.email | awk -F'@' '{print $1}' | xargs)
    if [ ! -z "$git_username" ]; then
      pipeline_name="${pipeline_name}-${git_username}"
    else
      echo "Error: couldn't find git config user.email"
      exit 1
    fi
  fi

  fly --target faas sync > /dev/null
  erb "${pipeline_filename}" > /dev/null

  gcp_key=$(lpass show --note Shared-pfs-eng/pfs-gcp-ci-svc)
  fly --target faas set-pipeline  --pipeline "${pipeline_name}" \
    --config <(erb "${pipeline_filename}") \
    --var branch-name="${branch_name}" \
    --var gcp-json-key="$gcp_key" \
    -l <(lpass show --note Shared-pfs-eng/pfs-gcp-ci-pipeline-secrets) \
    -l <(lpass show --note Shared-pfs-eng/pfs-gcp-kubeconfig-gke-ci) \
    ${@:2}
}

pushd "${ci_dir}" > /dev/null
  main "$@"
popd > /dev/null
