#!/bin/bash

set -exuo pipefail

CLIENT_ID=$(lpass show --note 'Shared-pfs-eng/pfs-ci-gitbot' | bosh int - --path='/oauth/client_id')
CLIENT_SECRET=$(lpass show --note 'Shared-pfs-eng/pfs-ci-gitbot' | bosh int - --path='/oauth/client_secret')

fly -t faas set-team -n pfs \
    --github-auth-client-id $CLIENT_ID \
    --github-auth-client-secret $CLIENT_SECRET \
    --github-auth-team pivotal-cf/pfs
