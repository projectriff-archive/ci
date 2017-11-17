#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"
SK8S_VERSION=$(determine_sk8s_version "$build_root/git-sk8s" "$build_root/sk8s-version")

pushd $build_root/git-sk8s/charts

  helm init --client-only

  sed -i -e 's/IfNotPresent/Always/g' "$build_root/git-sk8s/charts/sk8s/values.yaml"

  #topic_controller_version=$(head "$build_root/topic-controller-version/version")
  topic_controller_version="$SK8S_VERSION"
  http_gw_version=$(head "$build_root/http-gateway-version/version")
  sidecar_version=$(head "$build_root/sidecar-version/version")

  chart_version=$(grep version sk8s/Chart.yaml  | awk '{print $2}')

  helm package sk8s --version "$chart_version"

  chart_file=$(basename sk8s*tgz)

  cat > "${build_root}/sk8s-charts-install/sk8s-${chart_version}-install-example.sh" << EOM
#!/bin/bash

script_name=\`basename "\$0"\`

set -euo pipefail

if (( \$# < 1 )); then
    echo
    echo "Usage:"
    echo
    echo "   \$script_name <chart-name> <extra-helm-args>"
    echo
    exit 1
fi

set -x

chart_name="\$1"
shift

helm install "\${chart_name}" \
--version="${chart_version}" \
--set functionController.image.tag=${SK8S_VERSION},functionController.sidecar.image.tag=${sidecar_version},topicController.image.tag=${topic_controller_version},httpGateway.image.tag=${http_gw_version},zipkin.image.tag=${SK8S_VERSION} \
"\$@"

EOM

  cp "$chart_file" "$build_root/sk8s-charts/"

  set +e
  curl -sfL "$SK8S_CHARTS_URL/index.yaml" > existing_index.yaml
  if [ "0" != "$?" ]; then
    rm -f existing_index.yaml
  fi
  set -e

  if [ -f existing_index.yaml ]; then
    helm repo index "$build_root/sk8s-charts" --url "$SK8S_CHARTS_URL" --merge existing_index.yaml
  else
    helm repo index "$build_root/sk8s-charts" --url "$SK8S_CHARTS_URL"
  fi

popd
