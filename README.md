# PFS CI

### Concourse: https://ci.faas.to.cf-app.com
- GitHub auth; must belong to the `pivotal-cf/pfs` collaborator team
- Install `fly` locally (http://concourse.ci/single-page.html#fly-cli)
- Authenticate with Concourse: `fly -t faas login -c https://ci.faas.to.cf-app.com -k
- Install the LastPass CLI (`lpass`: https://github.com/lastpass/lastpass-cli) and ensure it is available on the `PATH`
- Log into LastPass CLI (must have access to the `Shared-pfs-eng` folder)
- When making changes to a pipeline, use `./set_pipeline.sh <pipeline-name>` to submit changes upstream

### Concourse BOSH
- Install the BOSH Bootloader CLI (`bbl`: https://github.com/cloudfoundry/bosh-bootloader)
- Install the BOSH CLI (`bosh`: https://bosh.io/docs/cli-v2.html#install)
- Log into LastPass (must have access to the `Shared-pfs-eng` folder)
- To set up the BBL environment, run `pfs-ci/concourse/bbl/bbl_setup.sh`
- To deploy Concourse, run `pfs-ci/concourse/deploy_concourse`

### Versioning
- Container images and Helm charts built from `riff` are versioned using the Concourse `semver` resource.
- Build numbers for container images are automatically bumped each time a container is built
- All other version changes are operator/developer controlled
#### Bumping Patch Version
- Run the `manual-images-version-bump-patch` job to bump the patch version (from `0.0.1-build.12` to `0.0.2-build.1`, for example)
#### Tagging Images for Release
- Run the `manual-images-release` job to tag the latest images with a stable [non-build] tag (Will tag a `0.0.1-build.12` image of a given component as `0.0.1`).

### Helm Charts
- Charts (and a corresponding `index.yaml` for the latest build) are published to https://riff-charts.storage.googleapis.com
- Default values in Helm charts need to be overridden with appropriate values, based on the container images used to make test the chart. A companion install script is published alongside each chart, named `riff-<version>-install-example.sh`
