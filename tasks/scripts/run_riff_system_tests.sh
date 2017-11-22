#!/bin/bash
set -exuo pipefail

echo "System Tests for riff"

build_root=$(pwd)

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
init_docker
init_kubeconfig

RIFF_VERSION=$(head "$build_root/gcs-riff-chart-latest-version/latest_version")
JAVA_INVOKER_VERSION=$(head "$build_root/java-function-invoker-version/version")
existing_riff_ns=$(find_existing_riff_ns "$RIFF_VERSION")

set +e
pgrep localkube
minikube_retcode=$?
set -e

host_jsonpath='{.items[0].status.loadBalancer.ingress[].ip}'
if [ "0" == "${minikube_retcode}" ]; then
  host_jsonpath='{.items[0].spec.clusterIP}'
fi
http_gw_host=$(kubectl -n "$existing_riff_ns" get svc -l component=http-gateway -o jsonpath=$host_jsonpath)
http_gw_port=$(kubectl -n "$existing_riff_ns" get svc -l component=http-gateway -o jsonpath='{.items[0].spec.ports[?(@.name == "http")].port}')

kafka_pod=$(kubectl -n "$existing_riff_ns"  get pod -l component=kafka-broker -o jsonpath='{.items[0].metadata.name}')

# init test env vars

export SYS_TEST_JAVA_INVOKER_VERSION="$JAVA_INVOKER_VERSION"
export SYS_TEST_NS="$existing_riff_ns"
export SYS_TEST_HTTP_GW_URL="http://${http_gw_host}:${http_gw_port}"
export SYS_TEST_KAFKA_POD_NAME="$kafka_pod"
export SYS_TEST_DOCKER_ORG="$DOCKER_ORG"
export SYS_TEST_DOCKER_USERNAME="$DOCKER_USERNAME"
export SYS_TEST_DOCKER_PASSWORD="$DOCKER_PASSWORD"
export SYS_TEST_BASE_DIR="$build_root/git-riff"
export SYS_TEST_MSG_RT_TIMEOUT_SEC=60

export GOPATH=$(go env GOPATH)
workdir=$GOPATH/src/github.com/pivotal-cf
mkdir -p $workdir
cp -rf git-pfs-system-test $workdir/pfs-system-test
cd $workdir/pfs-system-test
dep ensure

set +e
./test.sh
test_retcode="$?"
set -e

if [ "0" != "$test_retcode" ]; then
  echo "Tests Failed. Printing logs from all pods in [$existing_riff_ns]"

  kubectl get pods -n "$existing_riff_ns" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n' | xargs -I{} kubectl logs {} -n "$existing_riff_ns"
fi

exit $test_retcode
