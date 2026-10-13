<#
PowerShell script to create Azure prerequisite resources for the Day 02 CI/CD lab.
Requires: Azure CLI (az) logged in and permission to create resource groups and storage accounts.
Run: powershell -ExecutionPolicy Bypass -File .\create_azure_prereqs.ps1
#>
param(
  [string]$subscriptionId = "",
  [string]$backendResourceGroup = "tfstate-day2-rg",
  [string]$deploymentResourceGroup = "tf-day2-lab-rg",
  [string]$location = "westeurope",
  [string]$storageAccountName = "tfday2lab$(Get-Random -Maximum 999999)",
  [string]$containerName = "tfstate"
)

if(-not $subscriptionId){
  $subscriptionId = (az account show --query id -o tsv) 2>$null
}

Write-Host "Using subscription: $subscriptionId"

Write-Host "Creating backend resource group $backendResourceGroup in $location..."
az group create --name $backendResourceGroup --location $location | Out-Null

Write-Host "Creating deployment resource group $deploymentResourceGroup in $location..."
az group create --name $deploymentResourceGroup --location $location | Out-Null

Write-Host "Creating storage account $storageAccountName in $backendResourceGroup (Standard_LRS)..."
az storage account create --name $storageAccountName --resource-group $backendResourceGroup --location $location --sku Standard_LRS --kind StorageV2 | Out-Null

Write-Host "Creating storage container $containerName..."
$accountKey = az storage account keys list -g $backendResourceGroup -n $storageAccountName --query [0].value -o tsv
az storage container create --name $containerName --account-name $storageAccountName --account-key $accountKey | Out-Null

Write-Host "Recording sample backend and Azure DevOps setup data to prereqs_output.json."
$sample = @{
  sampleData = "true";
  notes = "This file is sample data only. Do not commit real credentials."
  subscriptionId = $subscriptionId;
  location = $location;
  backendResourceGroup = $backendResourceGroup;
  deploymentResourceGroup = $deploymentResourceGroup;
  storageAccountName = $storageAccountName;
  containerName = $containerName;
  terraformStateKey = "day2-lab.terraform.tfstate";
  serviceConnectionName = "TF-SERVICE-CONNECTION";
  authentication = "Azure Resource Manager Service Connection with Workload Identity Federation";
  azureDevOpsEnvironment = "production";
  roleScope = "Least privilege on the backend storage account and the tf-day2-lab-rg deployment resource group"
}
$sample | ConvertTo-Json -Depth 5 | Out-File -FilePath "prereqs_output.json" -Encoding utf8

Write-Host "Done. Next steps:"
Write-Host "  - Note the storage account name: $storageAccountName"
Write-Host "  - Create the Azure DevOps service connection in the portal using Workload Identity Federation."
Write-Host "  - Create the variable group 'TF-SECRETS' with ARM_BACKEND_RG, ARM_BACKEND_SA, ARM_BACKEND_CONTAINER, and ARM_BACKEND_KEY=day2-lab.terraform.tfstate."
Write-Host "  - Authorize the pipeline identity for the backend storage account and the tf-day2-lab-rg deployment resource group."
Write-Host "prereqs_output.json is sample data only and should not contain real credentials."
