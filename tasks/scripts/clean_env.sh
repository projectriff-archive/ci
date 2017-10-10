#!/bin/bash

set -exuo pipefail

login() {
  echo "$GOOGLE_CLOUD_KEYFILE_JSON" > gcp.json
  gcloud -q auth activate-service-account --key-file=gcp.json
  gcloud config set project "$PROJECT_ID"
}

delete_vips() {
  gcloud -q compute addresses list --format=json --filter="name~$ENV_PREFIX" |
    jq -r .[].name |
    xargs -I{} gcloud -q compute addresses delete {} --region=${REGION}
}

delete_lbs() {
  gcloud -q compute forwarding-rules list --format=json --filter="name~$ENV_PREFIX" |
    jq -r .[].name |
    xargs -I{} gcloud -q compute forwarding-rules delete {} --region=${REGION}

  gcloud -q compute target-pools list --format=json --filter="name~$ENV_PREFIX" |
    jq -r .[].name |
    xargs -I{} gcloud -q compute target-pools delete {} --region=${REGION}
}

delete_instances() {
  gcloud -q --format=json compute instances list --filter="networkInterfaces[0].network~$NETWORK_NAME" |
    jq -r  .[].name |
    xargs -I{} gcloud -q --format=json compute instances delete {} --delete-disks=all --zone=${AZ}
}

delete_firewall_rules() {
  gcloud -q --format=json compute firewall-rules list --filter="network~$NETWORK_NAME" |
    jq -r  .[].name |
    xargs -I{} gcloud -q --format=json compute firewall-rules delete {}
}

delete_routes() {
  # note : default local routes cannot be delete inline
  gcloud -q --format=json compute routes list --filter="network~$NETWORK_NAME" |
    jq -r  .[].name |
    xargs -I{} gcloud -q --format=json compute routes delete {} || true
}

delete_subnets() {
  gcloud -q --format=json compute networks subnets list --filter="network~$NETWORK_NAME" |
    jq -r  .[].name |
    xargs -I{} gcloud -q --format=json compute networks subnets delete {} --region=${REGION}
}

delete_network() {
  gcloud -q --format=json compute networks list --filter="name~$NETWORK_NAME" |
    jq -r  .[].name |
    xargs -I{} gcloud -q --format=json compute networks delete {}
}

delete_service_accounts() {
  gcloud -q --format=json iam service-accounts list --filter="email~$ENV_PREFIX" |
    jq -r .[].email |
    xargs -I{} gcloud -q --format=json iam service-accounts delete {}
}

get_service_account() {
  gcloud -q --format=json  projects get-iam-policy "${PROJECT_ID}" |
    jq -r  .bindings[].members[] |
    (grep "${ENV_PREFIX}" || true) |
    uniq
}

delete_service_account_bindings() {
  service_account=$(get_service_account)
  if [ -z "$service_account" ]; then
    return
  fi
  gcloud -q --format=json projects get-iam-policy "${PROJECT_ID}" |
  jq --arg env_prefix "${ENV_PREFIX}" '.bindings[] | select(any (.members[]; contains($env_prefix)))' |
  jq -r  .role |
  xargs -I{} \
    gcloud -q --format=json projects remove-iam-policy-binding "${PROJECT_ID}" \
      --member="${service_account}" \
      --role={}
}

create_network() {
  gcloud -q --format=json compute networks create "${NETWORK_NAME}" --mode=custom
}

login
delete_vips
delete_lbs
delete_instances
delete_firewall_rules
delete_routes
delete_subnets
delete_network
delete_service_accounts
delete_service_account_bindings
create_network
