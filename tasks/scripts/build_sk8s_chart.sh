#!/bin/bash

set -exuo pipefail

build_root=$PWD
SK8S_VERSION=$(head "$build_root/sk8s-version/version")

cd $build_root/git-sk8s

HELM_VALUES_OVERRIDE=""
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}eventDispatcher.image.repository=sk8s/event-dispatcher,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}eventDispatcher.image.tag=latest,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicController.image.repository=sk8s/topic-controller,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicController.image.tag=latest,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicGateway.image.repository=sk8s/topic-gateway,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicGateway.image.tag=latest,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}topicGateway.service.type=LoadBalancer,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}zipkin.image.repository=sk8s/zipkin-server,"
HELM_VALUES_OVERRIDE="${HELM_VALUES_OVERRIDE}zipkin.image.tag=latest"

pushd charts

    helm package sk8s --version="$SK8S_VERSION"

    chart_file=$(basename sk8s*tgz)

    cp "$chart_file" "$build_root/sk8s-charts/"

    helm repo index "$build_root/sk8s-charts" --url "https://sk8s_charts_dev.storage.googleapis.com"

popd
