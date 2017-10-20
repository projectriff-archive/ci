#!/bin/bash

tempdir=$(mktemp -d)
cd $tempdir
lpass show --note 'Shared-pfs-eng/pfs-concourse-bbl-state' | base64 -D | gunzip > bbl-state.json
bbl print-env
rm bbl-state.json
