# Azure DevOps configuration for the Day 02 CI/CD lab

This guide explains the lab’s recommended Azure DevOps setup using a shared Azure Storage backend and a service connection based on Workload Identity Federation (WIF). This is the primary path for the course lab.

## 1. Prerequisites

Before you start, confirm that you have:

- an Azure DevOps organization
- an Azure DevOps project
- a repository containing the lab files
- a hosted agent or equivalent execution environment
- access to the Terraform pipeline tasks in Azure DevOps
- permission to create and authorize a service connection
- permission to create and configure a variable group
- an Azure DevOps environment named `production` with approval configured

## 2. Azure platform prerequisites

Create the required Azure resources before the pipeline runs:

- backend resource group: `tfstate-day2-rg`
- deployment resource group: `tf-day2-lab-rg`
- Storage Account in the backend resource group
- blob container used for the remote Terraform state

Use the same backend values consistently in the pipeline and docs.

## 3. Azure DevOps service connection

In Azure DevOps, create a new Azure Resource Manager service connection named:

```text
TF-SERVICE-CONNECTION
```

Use the recommended authentication model:

- Azure Resource Manager Service Connection
- Workload Identity Federation
- no long-lived client secret required

The identity needs:

- storage data-plane authorization to the backend Storage Account in `tfstate-day2-rg`
- deployment permissions on `tf-day2-lab-rg`
- pipeline authorization to use the service connection

This is the primary setup path for the lab.

### LEGACY ALTERNATIVE

A secret-based Azure service principal flow may be retained only as a clearly marked legacy alternative for older environments. It is not the recommended lab path and should not be described as the default setup.

## 4. Create the variable group

Create an Azure DevOps variable group named `TF-SECRETS` and add these values:

- `ARM_BACKEND_RG` = `tfstate-day2-rg`
- `ARM_BACKEND_SA` = backend storage account name
- `ARM_BACKEND_CONTAINER` = blob container name
- `ARM_BACKEND_KEY` = `day2-lab.terraform.tfstate`

Do not treat `ARM_BACKEND_KEY` as a secret or a client credential. It is the remote state key, not a credential.

## 5. Azure DevOps environment approval

Configure the Azure DevOps environment named `production` with the required approval.

Important: approvals are configured on the environment in Azure DevOps, not in a YAML comment. The environment approval gate controls the apply stage.

The `CD_APPLY` stage must stay dependent on the successful `CI_SCAN_PLAN` stage and the environment approval.

## 6. Push the repo and create the pipeline

- commit the lab files
- push to the repository
- create a pipeline from `azure-pipelines.yml`

Use explicit staging instead of `git add .` during the lab.

```bash
git status
git add main.tf azure-pipelines.yml modules/simple_storage/main.tf
git commit -m "Remediate storage TLS"
git push origin main
```

## 7. Safety notes

- never store real Azure or Git credentials in source control
- do not commit `prereqs_output.json` if it contains generated values
- keep sample output placeholder-only if you must keep it in the repo
- do not use a realistic-looking `clientSecret` value in sample data

## 8. Final checklist

Before running the lab, confirm:

- the service connection name is `TF-SERVICE-CONNECTION`
- the authentication model is WIF
- the backend state key is `day2-lab.terraform.tfstate`
- the backend resource group is `tfstate-day2-rg`
- the deployment resource group is `tf-day2-lab-rg`
- the Checkov rule is `CKV_AZURE_44`
- the environment approval is configured on the `production` environment
- the pipeline apply step remains gated by CI success and approval
