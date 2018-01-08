#!/bin/bash

set -exu -o pipefail
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

rm -rf $script_dir/vars*
rm -f $script_dir/bbl-state.json
rm -f $script_dir/pfs-ci-key.json
rm -f $script_dir/bblenv
