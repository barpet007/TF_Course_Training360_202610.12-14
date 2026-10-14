param(
  [string]$Location = "westeurope",
  [string]$BackendResourceGroupName = "rg-lab03-backend",
  [string]$BackendStorageAccountName = "",
  [string]$BackendContainerName = "tfstate"
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw "Azure CLI is not installed. Install az before running this script."
}

$azLogin = az account show --query id -o tsv 2>$null
if (-not $azLogin) {
  Write-Host "You are not signed in to Azure CLI. Run 'az login' first."
  exit 1
}

if ([string]::IsNullOrWhiteSpace($BackendStorageAccountName)) {
  $randomSuffix = Get-Random -Minimum 1000 -Maximum 9999
  $BackendStorageAccountName = "stlab03$randomSuffix"
}

az group create --name $BackendResourceGroupName --location $Location | Out-Null
az storage account create --name $BackendStorageAccountName --resource-group $BackendResourceGroupName --location $Location --sku Standard_LRS --kind StorageV2 | Out-Null
az storage container create --name $BackendContainerName --account-name $BackendStorageAccountName | Out-Null

$storageKey = az storage account keys list --resource-group $BackendResourceGroupName --account-name $BackendStorageAccountName --query "[0].value" -o tsv

$summary = [ordered]@{
  backendResourceGroup = $BackendResourceGroupName
  backendStorageAccount = $BackendStorageAccountName
  backendContainer      = $BackendContainerName
  backendKey            = $storageKey
  serviceConnection     = "Already prepared from the previous lab"
  variableGroup         = "Already prepared from the previous lab"
}

$summary | ConvertTo-Json -Depth 3 | Out-File -FilePath (Join-Path $PSScriptRoot 'prereqs_output.json') -Encoding utf8
