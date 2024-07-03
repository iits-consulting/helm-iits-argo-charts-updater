#  infrastructure-charts

# Table of Content

  * [Usage](#usage)
    * [Requirements](#requirements)
    * [Introduction](#introduction)
    * [Register the ArgoCD repository to be deployed over Terraform](#register-the-argocd-repository-to-be-deployed-over-terraform)
    * [How to deploy some charts/services](#how-to-deploy-some-chartsservices)
      * [Full example of a deployment](#full-example-of-a-deployment)
    * [How to change values for my chart ?](#how-to-change-values-for-my-chart-)
        * [What should i declare inside](#what-should-i-declare-inside)
        * [What should i not declare here](#what-should-i-not-declare-here)
      * [Stage dependent App Values (values-dev.yaml)](#stage-dependent-app-values-values-devyaml)
        * [What should i declare inside](#what-should-i-declare-inside-1)
        * [What should i not declare here](#what-should-i-not-declare-here-1)
      * [Stage dependent values and parameters inside a valuesFile (values-dev.yaml)](#stage-dependent-values-and-parameters-inside-a-valuesfile-values-devyaml)
    * [Guideline how do i add a new feature](#guideline-how-do-i-add-a-new-feature)
      * [Guideline for local charts](#guideline-for-local-charts)
      * [Guideline for remote charts](#guideline-for-remote-charts)

## Usage

### Requirements

You need to setup the infrastructure-charts through this [ArgoCD Chart](https://github.com/iits-consulting/charts/tree/main/charts/argocd)

### Introduction

The git project _infrastructure-charts_ is automatically installed by this [ArgoCD Chart](https://github.com/iits-consulting/charts/tree/main/charts/argocd). It then creates
multiple other applications in the format of [app-of-apps pattern](https://argo-cd.readthedocs.io/en/stable/operator-manual/cluster-bootstrapping/#app-of-apps-pattern)

A example infrastructure-charts-repo you can find [here](https://github.com/iits-consulting/otc-infrastructure-charts-template)

Within `infrastructure-charts/values.yaml` you can add new services and customize them. [Helm tpl](https://helm.sh/docs/howto/charts_tips_and_tricks/#using-the-tpl-function) is supported within the _values.yaml_ file


### Register the ArgoCD repository to be deployed over Terraform

The app-charts repository needs first to be registered. Please go the Terraform project
and inside $STAGE/kubernetes folder add the following lines and `terraform apply` afterwards
every change on main will be auto applied.

```hcl

resource "helm_release" "argocd" {
  ...
  values = [
    yamlencode({
      projects = {
        ...
        app-charts = {
          # add here variables to give them over to argocd
          projectValues = {
             # Set this to enable stage $STAGE-values.yaml
             stage        = var.stage
             traefikElbId = module.terraform_secrets_from_encrypted_s3_bucket.secrets["elb_id"]
             rootDomain  = var.domain_name
          }
          git = {
            username = data.vault_generic_secret.gitlab.data["username"]
            password = data.vault_generic_secret.gitlab.data["access_token"]
            repoUrl  = "https://.../app-charts.git"
            branch   = "main"
          }
        }
      }
    })
  ]
}
```

All _projectValues_ variables are given over to argo, and we can reuse them here.

In this example the _stage_, _traefikElbId_, and _rootDomain_ variables are handed over to argo.
We would recommend to handle secrets over a proper security tooling like hashicorp vault.

### How to deploy some charts/services

You have 3 options to deploy some services.

1. Chart from a global helm chart registry. The default helm registry can be defined like this:
     ```yaml
    global:
      helm:
        repoURL: "https://charts.iits.tech"
      ```
   The global repoUrl can be helm registry or a git url.
   Then services can be registered and installed like this:
     ```yaml
    charts:
      iits-admin-dashboard:
      namespace: admin
      targetRevision: 1.3.0
      # values files needs to be inside this chart
      valueFile: "value-files/iits-admin-dashboard/values.yaml"
      ```   

2. Chart from a non global helm chart registry. Example:
     ```yaml
    bitnami-kafka:
      namespace: bitnami-kafka # Which namespace should the service be deployed
      repoURL: "https://charts.bitnami.com/bitnami" # Helm repo URL by default it takes the helm repo URL from line 11
      targetRevision: 22.1.5
      overrideChartName: kafka # You can override the chart name
      disableAutoSync: false # If set to true the sync will not happen automatically, you need to do it manually over the UI
      parameters:
        "kafka.replicaCount": "1"
      ```     
3. Chart which resides inside a git repository. Example:
     ```yaml
      # Local chart for development purposes
      akhq:
        namespace: kafka
        repoURL: "https://github.com/iits-consulting/otc-infrastructure-charts-template.git"
        targetRevision: "main"
        path: "local-charts/akhq"      
     ```    

#### Full example of a deployment

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

### How to change values for my chart ?

Example:
- infrastructure-charts = [values.yaml](infrastructure-charts%2Fvalues.yaml)

#####  What should i declare inside
* I declare here my services which i want to deploy
* Global helm charts values, example:
  ```yaml
  global:
    helm:
      parameters:
        rootDomain: "{{.Values.projectValues.rootDomain}}"
  ```
* Vault injection values, example:
  ```yaml
    my-frontend:
    namespace: my-namespace
    path: "local-charts/my-frontend"
    parameters:
      app.env.OBS_ACCESS_KEY_ID: "vault:{{.Values.projectValues.context}}/data/{{.Values.projectValues.stage}}/apps/apps_bucket#access_key"
  ```
* Stage dependent Variables
  ```yaml
    my-frontend:
    namespace: my-namespace
    path: "local-charts/my-frontend"
    parameters:
      app.ingressRoute.domain: "customSubDomain.{{.Values.projectValues.rootDomain}}"
      app.env.OBS_ACCESS_KEY_ID: "vault:{{.Values.projectValues.context}}/data/{{.Values.projectValues.stage}}/apps/apps_bucket#access_key"
  ```
* Helm tpl works here

#####  What should i not declare here
* Static parameters about a specific chart, example: app.env.QUARKUS_HTTP_PORT: "9000"
* Image tags for app charts these ones are stage dependent, example: app.image.tag: "7.4.22-SNAPSHOT"
* If you need to set more then 10 Parameters please use valueFile example:
  ```yaml
    my-frontend:
      valueFile: "app-values/my-frontend/values.yaml"
  ```

#### Stage dependent App Values (values-dev.yaml)

Example:
- infrastructure-charts = [values.yaml](infrastructure-charts%2Fvalues-dev.yaml)

#####  What should i declare inside
* very stage dependent parameters which can't be templated with helm inside the values.yaml
* Image tags for the app charts (are normally set over the CI/CD Tool/pipeline)

#####  What should i not declare here
* Everything from this Point [What should i declare inside](#what-should-i-declare-inside)

#### Stage dependent values and parameters inside a valuesFile (values-dev.yaml)

Sometimes you need to set a lot of parameters and informations which are context and stage specific. For this case we use a specific
valuesFile. This is especially necessary if we use a public third party helm chart.

Example:
  ```yaml
    keycloak:
      namespace: my-namespace
      repoURL: "https://charts.iits.tech"
      targetRevision: "0.1.6"
      valueFile: "app-values/keycloak/values.yaml"
  ```

Important vault references needs to wrapped with ${} like this: "${vault:....}"


### Guideline how do i add a new feature

To keep the main/master branch clean we would recommend the following approach.


#### Guideline for local charts

1. Register your service inside the `infrastructure-charts/values.yaml` or
   `app-charts/values.yaml` first. If the service already exists, change the `targetRevision` from this service
   from `master/main` to `feat/my-feature-description` and push the change to `master/main`
2. Create a new local branch called `feat/my-feature-description`
3. Perform your changes and push to the remote branch `feat/my-feature-description`
4. ArgoCD should automatically deploy your changes
5. When you finished with your feature development,
   change the `targetRevision` back to `master/main` and commit and push to `master/main`

#### Guideline for remote charts

We would recommend if it is not a small change to download the chart and work first
with the local chart as descriped in the step [above](#guideline-for-local-charts).

When you are done push it to the remote helm registry.
