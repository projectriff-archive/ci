#!/bin/bash

set -exuo pipefail
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

deployment_name="pfs-gcp-concourse-2"

github_client_id=$(lpass show --note 'Shared-pfs-eng/pfs-ci-gitbot' | bosh int - --path='/oauth_ci2/client_id')
github_client_secret=$(lpass show --note 'Shared-pfs-eng/pfs-ci-gitbot' | bosh int - --path='/oauth_ci2/client_secret')
github_authorize='{"organization": "pivotal-cf", "teams": ["pfs"]}'

git clone https://github.com/concourse/concourse-deployment.git "$script_dir/concourse-deployment"

pushd "$script_dir/concourse-deployment/cluster"

  concourse_deployment_sha=$(git rev-parse HEAD)

  patch concourse.yml "$script_dir/concourse.yml.patch"

  bosh -e ${BOSH_ENVIRONMENT} deploy -d "${deployment_name}" concourse.yml \
    -l ../versions.yml \
    --vars-file "${script_dir}/deploy_concourse_vars.yml" \
    --vars-store "${script_dir}/creds-${deployment_name}.yml" \
    -o operations/tls.yml \
    -o operations/scale.yml \
    -o operations/privileged-https.yml \
    -o operations/github-auth.yml \
    --var deployment_name=${deployment_name} \
    --var github_client.username=${github_client_id} \
    --var github_client.password=${github_client_secret}

popd

rm -rf "$script_dir/concourse-deployment/cluster"

set +x
echo "---------------------------------"
echo
echo "Deployed [$deployment_name] using concourse-deployment [$concourse_deployment_sha]"
echo
echo "Concourse creds: ${script_dir}/creds-${deployment_name}.yml"
echo
echo "---------------------------------"
