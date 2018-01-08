#!/bin/bash

set -exu -o pipefail
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

pushd $script_dir

  lpass show --note 'Shared-pfs-eng/pfs-concourse-bosh-bbl-vars' | base64 -D | tar xJvf -
  lpass show --note 'Shared-pfs-eng/pfs-concourse-bosh-bbl-vars-tf' | base64 -D | tar xJvf -
  lpass show --note 'Shared-pfs-eng/pfs-concourse-bosh-bbl-vars-director' | base64 -D | tar xJvf -
  mv vars_tf/* vars/
  mv vars_director/* vars/
  rm -r vars_tf
  rm -r vars_director

  lpass show --note 'Shared-pfs-eng/pfs-concourse-bosh-bbl-state' > "$script_dir/bbl-state.json"
  lpass show --note 'Shared-pfs-eng/pfs-gcp-ci-svc' > "$script_dir/pfs-ci-key.json"

  bbl print-env

  set +x
  echo " ------------------------ "
  echo "|  Run This              |"
  echo " ------------------------ "
  echo
  echo " bbl -s $script_dir print-env > $script_dir/bblenv && source $script_dir/bblenv && rm $script_dir/bblenv && $script_dir/bbl_clean.sh "
  echo
  echo

popd
