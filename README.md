# iits-consulting ArgoCD App of Apps Chart Updater

## Description

To use everytime the latest version across the projects we need to centralize it.
If you execute the plugin inside the App-of-Apps Chart it will automatically update the files.

It is designed for projects like this: https://github.com/iits-consulting/otc-infrastructure-charts-template


## Usage


```shell
helm plugin install https://github.com/iits-consulting/helm-iits-argo-charts-updater
#We would recommend to put this also into your .bash_aliases
alias chartUpdater="helm plugin update iits-argo-charts-updater && helm iits-argo-charts-updater"
cd infrastructure-charts
# This will update the files
chartUpdater
```