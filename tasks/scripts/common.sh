#!/bin/bash

function init_kubeconfig(){
  if [ ! -z "$KUBECONFIG_STRING" ]; then
    mkdir ~/.kube
    echo "$KUBECONFIG_STRING" > ~/.kube/config
    mkdir -p ~/.kube/certs
    echo "$KUBECONFIG_CERT" > ~/.kube/certs/kube.crt
    echo "$KUBECONFIG_KEY" > ~/.kube/certs/kube.key
  fi
}

function init_docker(){
  if [ ! -z "$KUBECONFIG_STRING" ]; then
    start_docker
  fi
}

function generate_tiller_ns_name(){
  local _riff_name="$1"
  local _riff_version="$2"
  local _suffix="$3"
  local _sanitized_version=$(echo "$_riff_version" | sed 's/\./-/g' |  awk '{print tolower($0)}')
  echo "tiller-${_riff_name}-${_sanitized_version}-${_suffix}"
}

function generate_riff_ns_name(){
  local _riff_name="$1"
  local _riff_version="$2"
  local _suffix="$3"
  local _sanitized_version=$(echo "$_riff_version" | sed 's/\./-/g' |  awk '{print tolower($0)}')
  echo "${_riff_name}-${_sanitized_version}-${_suffix}"
}

function find_existing_tiller_ns(){
  local _riff_name="$1"
  local _riff_version="$2"
  local _sanitized_version=$(echo "$_riff_version" | sed 's/\./-/g' |  awk '{print tolower($0)}')

  set +e
  existing_tiller_ns_name=$(kubectl get ns | grep "tiller-${_riff_name}-${_sanitized_version}-" | awk '{print $1}')
  set -e
  echo "$existing_tiller_ns_name"
}

function find_existing_riff_ns(){
  local _riff_name="$1"
  local _riff_version="$2"
  local _sanitized_version=$(echo "$_riff_version" | sed 's/\./-/g' |  awk '{print tolower($0)}')

  set +e
  existing_riff_ns_name=$(kubectl get ns | grep "${_riff_name}-${_sanitized_version}-" | awk '{print $1}')
  set -e
  echo "$existing_riff_ns_name"
}

function determine_riff_version(){
  local _riff_git_dir="$1"
  local _riff_version_dir="$2"
  local _riff_version=$(head "$_riff_version_dir/version")

  cd "$_riff_git_dir"
  set +e
  local _pr_number=$(git config --local --get pullrequest.id)
  set -e

  if [ -z "$_pr_number" ]; then
    echo "$_riff_version"
  else
    echo "0.0.0-pr${_pr_number}"
  fi
}

function strip_snapshot_from_version(){
  echo "$1" | awk -F'-' '{print $1}'
}
