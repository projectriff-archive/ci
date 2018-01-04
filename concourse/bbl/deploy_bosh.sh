#!/bin/bash

set -exu -o pipefail
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

lpass show --note 'Shared-pfs-eng/pfs-concourse-bbl-state' | base64 -D | gunzip > "$script_dir/bbl-state.json"
lpass show --note 'Shared-pfs-eng/pfs-gcp-ci-svc' > "$script_dir/pfs-ci-key.json"

bbl up \
  --state-dir $PWD \
  --gcp-zone us-central1-c \
  --gcp-region us-central1 \
  --gcp-service-account-key "$script_dir/pfs-ci-key.json" \
  --gcp-project-id cf-spring-pfs-eng \
  --iaas gcp \
  --debug

rm "$script_dir/pfs-ci-key.json"
