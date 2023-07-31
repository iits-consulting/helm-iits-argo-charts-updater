## Usage infrastructure-charts repo

### Requirements

You need to setup the infrastructure-charts through this [ArgoCD Chart](https://github.com/iits-consulting/charts/tree/main/charts/argocd)

### Introduction

The git project _infrastructure-charts_ is automatically installed by this [ArgoCD Chart](https://github.com/iits-consulting/charts/tree/main/charts/argocd). It then creates
multiple other applications in the format of [app-of-apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern)

A example infrastructure-charts-repo you can find [here](https://github.com/iits-consulting/otc-infrastructure-charts-template)

Within `infrastructure-charts/values.yaml` you can add new services and customize them. [Helm tpl](https://helm.sh/docs/howto/charts_tips_and_tricks/#using-the-tpl-function) is supported within the _values.yaml_ file

### How to deploy some charts/services

You have 3 options to deploy some services.

1. Chart from a global helm chart registry which is configured in line number 12 (in this example we use https://charts.iits.tech/).
   Charts deployed like this:
   _argocd-config_, _otc-storage-classes_, _traefik_, _cert-manager_, _basic-auth-gateway_, _kafka_, _admin-dashboard_


2. Chart from a non global helm chart registry. Charts deployed like this: _bitnami-kafka_
3. Chart which resides inside this git repository. Charts deployed like this: _akhq_

#### Example Deployment

In this example we want to deploy elastic-stack (kibana/elasticsearch/filebeat)
* Open _infrastructure-charts/values.yaml_
* Add a new service like this:
  ```yaml
  elastic-stack:
    namespace: monitoring
    targetRevision: "7.17.3-route-bugfix"
  ```
You need to commit and push this change now. Argo detects the changes and applies them after around 2-3 minutes.

After deployment please update the admin dashboard (infrastructure-charts/values-files/admin-dashboard/values.yaml) with the new links.
* /kibana
* /elasticsearch

If you don't want to search for icons you can see the solution here: https://github.com/iits-consulting/charts/blob/main/charts/iits-admin-dashboard/files/index.html

### How to change values of the charts

You have 3 ways of changing the values of a chart

1. You change the values inside the remote/local helm chart itself
2. You set parameters inside the "infrastructure-charts/values.yaml" like shown between line number 55 till 57.
   We would recommend this approach if you need to template values or if you have just a few values which needs to be set.
3. You specify the location of a _values.yaml_ file like shown on line number 82.
   We would recommend this approach only if you have a lot of static values which are not stage dependent.

### Handover variables from Terraform to ArgoCD

Since this setup is build on top of the otc-terraform-template you can hand over information from terraform to argo like this:

```terraform
resource "helm_release" "argocd" {
  ...
  values                = [
    yamlencode({
      projects = {
        infrastructure-charts = {
          projectValues = {
            # Set this to enable stage $STAGE-values.yaml
            stage        = var.stage
            traefikElbId = module.terraform_secrets_from_encrypted_s3_bucket.secrets["elb_id"]
            rootDomain  = var.domain_name
            storageClassKmsKeyId = module.terraform_secrets_from_encrypted_s3_bucket.secrets["storage_class_kms_key_id"]
          }
      ...
    }
    )
  ]
}
```
All _projectValues_ variables are given over to argo, and we can reuse them here.

In this example the _stage_, _traefikElbId_, _adminDomain_ _storageClassKmsKeyId_ variables are handed over to argo.