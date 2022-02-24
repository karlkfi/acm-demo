# gke-west-mci

## Description
sample description

## Usage

### Fetch the package
`kpt pkg get REPO_URI[.git]/PKG_PATH[@VERSION] gke-west-mci`
Details: https://kpt.dev/reference/cli/pkg/get/

### View package content
`kpt pkg tree gke-west-mci`
Details: https://kpt.dev/reference/cli/pkg/tree/

### Apply the package
```
kpt live init gke-west-mci
kpt live apply gke-west-mci --reconcile-timeout=2m --output=table
```
Details: https://kpt.dev/reference/cli/live/
