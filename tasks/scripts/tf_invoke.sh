#!/bin/bash

set -exu -o pipefail

source ~/.bash_profile

build_root=$(pwd)

tf_iaas_src_dir="$1"
tf_routing_src_dir="$2"
existing_iaas_state="$build_root/git-pfs-ci/state/tf/$ENV_PREFIX.iaas.terraform.tfstate"
existing_routing_state="$build_root/git-pfs-ci/state/tf/$ENV_PREFIX.routing.terraform.tfstate"

touch "$build_root/tf-output/iaas.terraform.tfstate"
touch "$build_root/tf-output/routing.terraform.tfstate"

if [ -f "$existing_iaas_state" ]; then
  cp "$existing_iaas_state" "$build_root/tf-output/iaas.terraform.tfstate"
fi

if [ -f "$existing_routing_state" ]; then
  cp "$existing_routing_state" "$build_root/tf-output/routing.terraform.tfstate"
fi

function onexit(){
  date
  echo "EXITING..."
  echo

  echo "IaaS TF State"
  cat "$build_root/tf-output/iaas.terraform.tfstate"
  echo

  echo "Routing TF State"
  cat "$build_root/tf-output/routing.terraform.tfstate"
  echo
}
trap onexit INT TERM EXIT


echo "Paving IaaS"

# IaaS Paving
cd "$build_root/$tf_iaas_src_dir"
ls -lath
terraform init
terraform "${COMMAND}" \
  -var service_account_email="${SERVICE_ACCOUNT_EMAIL}" \
  -var projectid="${PROJECT_ID}" \
  -var network="${NETWORK_NAME}"  \
  -var prefix="${ENV_PREFIX}" \
  -var zone="${AZ}" \
  -var region="${REGION}" \
  -var subnet_ip_prefix="${SUBNET_IP_PREFIX}" \
  -state="$build_root/tf-output/iaas.terraform.tfstate" \
  -auto-approve

echo "Paving Routing"

# Routing
cd "$build_root/$tf_routing_src_dir"
ls -lath
terraform init

sed -i -e  's/credentials = ""//g' *.tf

terraform "${COMMAND}" \
  -var projectid="${PROJECT_ID}" \
  -var network="${NETWORK_NAME}"  \
  -var prefix="${ENV_PREFIX}" \
  -var zone="${AZ}" \
  -var region="${REGION}" \
  -var ip_cidr_range="${SUBNET_IP_PREFIX}.0/24" \
  -state="$build_root/tf-output/routing.terraform.tfstate" \
  -auto-approve

terraform output -state="$build_root/tf-output/routing.terraform.tfstate"  kubo_master_target_pool > "$build_root/tf-output/master_target_pool"
terraform output -state="$build_root/tf-output/routing.terraform.tfstate"  master_lb_ip_address > "$build_root/tf-output/kubernetes_master_host"

echo "Saving Outputs"

echo "$GOOGLE_CLOUD_KEYFILE_JSON" > gcp.json

gcloud -q auth activate-service-account --key-file=gcp.json

gcloud config set project "$PROJECT_ID"

set +e
while true; do
  motd_file_out=$(gcloud -q compute ssh --command 'file /etc/motd' "${ENV_PREFIX}bosh-bastion" --zone "${AZ}")
  echo "$motd_file_out" | grep "No such file or directory"
  if [ "0" == "$?" ]; then
    break
  fi
  echo "Waiting for bastion startup scripts to become ready..."
  sleep 2
done
set -e

gcloud -q compute scp "${ENV_PREFIX}bosh-bastion:/usr/bin/set_iaas_routing" "$build_root/tf-output/"  --zone ${AZ}
gcloud -q compute scp "${ENV_PREFIX}bosh-bastion:/usr/bin/update_gcp_env" "$build_root/tf-output/"  --zone ${AZ}
