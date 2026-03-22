# Re-creating with Arc
kubectl get pods -n azure-arc
az connectedk8s show --name <YourArcClusterName> --resource-group <YourResourceGroup>

az connectedk8s connect --name <YourArcClusterName> --resource-group <YourResourceGroup>
## Prerequisites

* Your k8s setup is in an accessible git repository
* Your app is Docker image is built
* Azure resource group exists
* Azure extensions are installed 
* Azure providers are installed

### Tips regarding prerequisites

**Add Azure resource groups**

```bash
az group create --name Hybrid-Lab --location northeurope
```

**Azure setup**

This tells the Azure CLI: "I’m a hobbyist, I know these are preview features, go ahead and install them."

```bash
az config set extension.dynamic_install_allow_preview=true
```

**The extensions and providers**

```bash
az provider register --namespace Microsoft.OperationalInsights
az provider register --namespace Microsoft.KeyVault
```

These are slow, you can check status with

```bash
az provider show -n Microsoft.OperationalInsights --query "registrationState"
az provider show -n Microsoft.KeyVault --query "registrationState"
```

For the other providers see [Getting Started Phase 8](01-getting-started.md)

## Switch to using Azure Key Vault

### Create the Key Vault

```bash
$VAULT_NAME = "hobby-vault-$(Get-Random)" # Vault names must be globally unique
$RG_NAME = "Hybrid-Lab"
$LOCATION = "northeurope"
az keyvault create --name $VAULT_NAME --resource-group $RG_NAME --location $LOCATION
```

### Add your Postgres password as a Secret

```bash
$MY_EMAIL = (az ad signed-in-user show --query userPrincipalName -o tsv)
az role assignment create `
    --role "Key Vault Secrets Officer" `
    --assignee $MY_EMAIL `
    --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/Microsoft.KeyVault/vaults/$VAULT_NAME"
```

```bash
az keyvault secret set --vault-name $VAULT_NAME --name "pg-password" --value "MySuperSecret123"
az keyvault secret set --vault-name $VAULT_NAME --name "pg-user" --value "pg-username"
az keyvault secret set --vault-name $VAULT_NAME --name "cf-tunnel-token" --value "MASSIVE_TOKEN_HERE"
```

## Create

Run script ```Deploy-Lab.ps1```
