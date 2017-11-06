#!/bin/bash

function determine_sk8s_version(){
  local _sk8s_git_dir="$1"
  local _sk8s_version_dir="$2"
  local _sk8s_version=$(head "$_sk8s_version_dir/version")

  cd "$_sk8s_git_dir"
  set +e
  local _pr_number=$(git config --local --get pullrequest.id)
  set -e

  if [ -z "$_pr_number" ]; then
    echo "$_sk8s_version"
  else
    echo "0.0.0-pr${_pr_number}"
  fi
}
