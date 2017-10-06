#!/bin/bash

set -exu -o pipefail

bbl up \
  --state-dir $PWD \
  --gcp-zone us-central1-c \
  --gcp-region us-central1 \
  --gcp-service-account-key \
  ~/.gcloud/pfs-ci-key.json \
  --gcp-project-id cf-spring-pfs-eng \
  --iaas gcp \
  --debug
