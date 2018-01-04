#!/bin/bash

set -exu -o pipefail

lpass show --note 'Shared-pfs-eng/pfs-concourse-bbl-state' | base64 -D | gunzip > bbl-state.json
lpass show --note 'Shared-pfs-eng/pfs-gcp-ci-svc' > pfs-ci-key.json

bbl up \
  --state-dir $PWD \
  --gcp-zone us-central1-c \
  --gcp-region us-central1 \
  --gcp-service-account-key pfs-ci-key.json \
  --gcp-project-id cf-spring-pfs-eng \
  --iaas gcp \
  --debug

rm pfs-ci-key.json
