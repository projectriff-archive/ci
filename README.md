# PFS CI

### Concourse: https://ci.faas.to.cf-app.com
- Login to the `pfs` team (via GitHub - must belong to the `pfs` collaborator team)
- Install `fly` locally (http://concourse.ci/single-page.html#fly-cli)
- Authenticate with Concourse: `fly -t faas login -c https://ci.faas.to.cf-app.com -k -n pfs`
- Install the LastPass CLI (`lpass`: https://github.com/lastpass/lastpass-cli) and ensure it is available on the `PATH`
- Log into LastPass (must have access to the `Shared-pfs-eng` folder)
- When making changes to a pipeline, use `./set_pipeline <pipeline-name>` to submit changes upstream

### Concourse BOSH 
- Install the BOSH Bootloader CLI (`bbl`: https://github.com/cloudfoundry/bosh-bootloader)
- Install the BOSH CLI (`bosh`: https://bosh.io/docs/cli-v2.html#install)
- Log into LastPass (must have access to the `Shared-pfs-eng` folder)
- To export environment variables for BOSH access, run: `eval "$(./concourse/bbl/print_bbl_env.sh)"` in the `pfs-ci` directory

### Versioning
Container images and Helm charts built from `sk8s` are versioned using the Concourse `semver` resource.

### Helm Charts
Charts (and a corresponding `index.yaml` for the latest build) are published to https://sk8s_charts.storage.googleapis.com

### CI Flow
![PFS CI flow](faas_ci_process.png)
