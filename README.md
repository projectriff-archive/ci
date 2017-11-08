# PFS CI

For concourse bosh access

```
eval "$(./concourse/bbl/print_bbl_env.sh)"
```
### Versioning
Container images and Helm charts built from `sk8s` are versioned using the Concourse `semver` resource.

### Helm Charts
Charts (and a corresponding `index.yaml` for the latest build) are published to https://sk8s_charts.storage.googleapis.com


### Concourse: https://ci.faas.to.cf-app.com

### CI Flow
![PFS CI flow](faas_ci_process.png)
