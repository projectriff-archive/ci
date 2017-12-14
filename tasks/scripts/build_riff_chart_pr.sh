#!/bin/bash

set -exuo pipefail

build_root=$PWD

source "$build_root/git-pfs-ci/tasks/scripts/common.sh"

cp -pr $build_root/git-helm-charts $build_root/riff

pushd $build_root/git-helm-charts

  helm init --client-only

  # override pull policy for PRs, since the name PR version can easily have multiple commits
  sed -i -e 's/IfNotPresent/Always/g' "$build_root/git-helm-charts/riff/values.yaml"

  chart_version=$(determine_riff_version "$build_root/git-riff-component-pr" "/dev/null")
  chart_name="riff${RIFF_COMPONENT_SHORTNAME}"

  case "$RIFF_COMPONENT_SHORTNAME" in
  "httpgw")
    chart_image_override="httpGateway.image.repository=${DOCKERHUB_ORG}/http-gateway"
    function_controller_version=$(head "$build_root/function-controller-version/version")
    topic_controller_version=$(head "$build_root/topic-controller-version/version")
    http_gateway_version="$chart_version"

    ;;
  "tctrl")
    chart_image_override="topicController.image.repository=${DOCKERHUB_ORG}/topic-controller"
    function_controller_version=$(head "$build_root/function-controller-version/version")
    http_gateway_version=$(head "$build_root/http-gateway-version/version")
    topic_controller_version="$chart_version"

    ;;
  "fctrl")
    chart_image_override="functionController.image.repository=${DOCKERHUB_ORG}/function-controller"
    topic_controller_version=$(head "$build_root/topic-controller-version/version")
    http_gateway_version=$(head "$build_root/http-gateway-version/version")
    function_controller_version="$chart_version"

    ;;
  *)
    echo "Invalid component specified for PR chart: [$RIFF_COMPONENT_SHORTNAME]"
    exit 1
    ;;
  esac

  cat "$build_root/git-helm-charts/riff/Chart.yaml" | sed -e "s/name: riff/name: $chart_name/g" -e "s/version.*/version: $chart_version/g" > "$build_root/git-helm-charts/riff/Chart.yaml.new"

  mv riff "$chart_name"

  mv "$build_root/git-helm-charts/$chart_name/Chart.yaml.new" "$build_root/git-helm-charts/$chart_name/Chart.yaml"

  helm package "$chart_name" --version "$chart_version"

  chart_file=$(basename ${chart_name}*tgz)

  cat > "${build_root}/helm-charts-install/${chart_name}-${chart_version}-install-example.sh" << EOM
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
--set functionController.image.tag=${function_controller_version},functionController.sidecar.image.tag=${function_sidecar_version},topicController.image.tag=${topic_controller_version},httpGateway.image.tag=${http_gateway_version},${chart_image_override} \
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
  echo "$chart_name" > "$build_root/helm-charts-latest-name/latest_name"

popd
