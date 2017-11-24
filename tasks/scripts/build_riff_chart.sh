#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"

cp -pr $build_root/git-helm-charts $build_root/riff

pushd $build_root/riff

  helm init --client-only

  chart_version=$(grep version Chart.yaml  | awk '{print $2}')

  sed -i -e 's/IfNotPresent/Always/g' "$build_root/riff/values.yaml"
  cp "$build_root/riff/values.yaml" "$build_root/helm-charts/values-snapshot.yaml"

  sed -i -e "s/0.0.1-SNAPSHOT/${chart_version}-SNAPSHOT/g" "$build_root/helm-charts/values-snapshot.yaml"

  function_controller_version=$(head "$build_root/function-controller-version/version")
  function_sidecar_version=$(head "$build_root/function-sidecar-version/version")
  topic_controller_version=$(head "$build_root/topic-controller-version/version")
  http_gateway_version=$(head "$build_root/http-gateway-version/version")


  helm package . --version "$chart_version"

  chart_file=$(basename riff*tgz)

  cat > "${build_root}/helm-charts-install/riff-${chart_version}-install-example.sh" << EOM
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
--set functionController.image.tag=${function_controller_version},functionController.sidecar.image.tag=${function_sidecar_version},topicController.image.tag=${topic_controller_version},httpGateway.image.tag=${http_gateway_version} \
"\$@"

EOM

  cp "$chart_file" "$build_root/helm-charts/"

  set +e
  curl -sfL "$HELM_CHARTS_URL/index.yaml" > existing_index.yaml
  if [ "0" != "$?" ]; then
    rm -f existing_index.yaml
  fi
  set -e

  if [ -f existing_index.yaml ]; then
    helm repo index "$build_root/helm-charts" --url "$HELM_CHARTS_URL" --merge existing_index.yaml
  else
    helm repo index "$build_root/helm-charts" --url "$HELM_CHARTS_URL"
  fi

  echo "$chart_version" > "$build_root/helm-charts-latest-version/latest_version"

popd
