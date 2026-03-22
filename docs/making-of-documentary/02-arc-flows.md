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

**Tips**

Add Azure resource groups

```bash
az group create --name Hybrid-Lab --location northeurope
```

The extensions and providers

(See [Getting Started Phase 8](01-getting-started.md))

## Create

Run script ```Deploy-Lab.ps1```
