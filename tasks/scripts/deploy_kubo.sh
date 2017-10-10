#!/bin/bash

set -exu -o pipefail

apt-get update && apt-get install -y bsdmainutils jq

mkdir -p "$PWD/kubo_envs"
unpacked_dir/bin/generate_env_config "$PWD/kubo_envs"  "$ENV_PREFIX" gcp
tf-output/update_gcp_env "$PWD/kubo_envs/$ENV_PREFIX/director.yml"

export master_target_pool=$(cat tf-output/master_target_pool)
export kubernetes_master_host=$(cat tf-output/kubernetes_master_host)
tf-output/set_iaas_routing "$PWD/kubo_envs/$ENV_PREFIX/director.yml"

echo

cat "$PWD/kubo_envs/$ENV_PREFIX/director.yml"

cp "$PWD/kubo_envs/$ENV_PREFIX/director.yml" env-output/

if [ ! -z "$BOSH_CREDS" ]; then
  echo "$BOSH_CREDS" > "$PWD/kubo_envs/$ENV_PREFIX/creds.yml"
fi

if [ -f "git-pfs-ci/state/bosh/${ENV_PREFIX}.bosh.state.json" ]; then
  cp "git-pfs-ci/state/bosh/${ENV_PREFIX}.bosh.state.json" "$PWD/kubo_envs/$ENV_PREFIX/state.json"
fi

function onexit(){
  date
  echo "Exiting"

  touch "$PWD/kubo_envs/$ENV_PREFIX/creds.yml"
  touch "$PWD/kubo_envs/$ENV_PREFIX/state.json"

  echo

  cat "$PWD/kubo_envs/$ENV_PREFIX/creds.yml"
  echo
  cat "$PWD/kubo_envs/$ENV_PREFIX/state.json"
  echo
  cat "$PWD/kubo_envs/$ENV_PREFIX/director.yml"

}

trap onexit INT TERM EXIT

echo "$GOOGLE_CLOUD_KEYFILE_JSON" > "$PWD/kubo_envs/$ENV_PREFIX/gcp.json"

gcloud -q auth activate-service-account --key-file="$PWD/kubo_envs/$ENV_PREFIX/gcp.json"

gcloud config set project "$PROJECT_ID"

gcloud -q components update

gcloud -q compute ssh --zone "${AZ}" "${ENV_PREFIX}bosh-bastion" --command "mkdir -p /share/env/$ENV_PREFIX"

gcloud -q compute scp --zone "${AZ}" "$PWD/kubo_envs/$ENV_PREFIX/gcp.json" "${ENV_PREFIX}bosh-bastion":"/share/env/$ENV_PREFIX/"
gcloud -q compute scp --zone "${AZ}" "$PWD/kubo_envs/$ENV_PREFIX/director.yml" "${ENV_PREFIX}bosh-bastion":"/share/env/$ENV_PREFIX/"

if [ -f "$PWD/kubo_envs/$ENV_PREFIX/creds.yml" ]; then
  gcloud -q compute scp --zone "${AZ}" "$PWD/kubo_envs/$ENV_PREFIX/creds.yml" "${ENV_PREFIX}bosh-bastion":"/share/env/$ENV_PREFIX/"
fi
if [ -f "$PWD/kubo_envs/$ENV_PREFIX/state.json" ]; then
  gcloud -q compute scp --zone "${AZ}" "$PWD/kubo_envs/$ENV_PREFIX/state.json" "${ENV_PREFIX}bosh-bastion":"/share/env/$ENV_PREFIX/"
fi

gcloud -q compute ssh --zone "${AZ}" "${ENV_PREFIX}bosh-bastion" --command "sed -i -e 's/n1-standard-1/n1-standard-4/g' /share/kubo-deployment/bosh-deployment/gcp/cpi.yml"
gcloud -q compute ssh --zone "${AZ}" "${ENV_PREFIX}bosh-bastion" --command "/share/kubo-deployment/bin/deploy_bosh /share/env/$ENV_PREFIX/ /share/env/$ENV_PREFIX/gcp.json"

gcloud -q compute scp --zone "${AZ}" "${ENV_PREFIX}bosh-bastion":"/share/env/$ENV_PREFIX/creds.yml"  "$PWD/kubo_envs/$ENV_PREFIX/creds.yml"
gcloud -q compute scp --zone "${AZ}" "${ENV_PREFIX}bosh-bastion":"/share/env/$ENV_PREFIX/state.json" "$PWD/kubo_envs/$ENV_PREFIX/state.json"

gcloud -q compute ssh --zone "${AZ}" "${ENV_PREFIX}bosh-bastion" --command "/share/kubo-deployment/bin/deploy_k8s /share/env/$ENV_PREFIX/ ${ENV_PREFIX}k8s public"

gcloud -q compute ssh --zone "${AZ}" "${ENV_PREFIX}bosh-bastion" --command "/share/kubo-deployment/bin/set_kubeconfig /share/env/$ENV_PREFIX/ ${ENV_PREFIX}k8s"

echo

gcloud -q compute ssh --zone "${AZ}" "${ENV_PREFIX}bosh-bastion" --command "kubectl config view --raw=true"
