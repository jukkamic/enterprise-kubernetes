# Enterprise Kubernetes Local Lab (Kind + Azure Arc + Key Vault + Flux)

Welcome to the Enterprise Kubernetes Local Lab! This guide walks you through setting up a robust, locally hosted Kubernetes cluster that behaves like a production-grade enterprise environment.

We are using **Kind (Kubernetes IN Docker)** on Windows, but managing it exactly as you would a remote production cluster. By integrating **Azure Arc**, **Flux (GitOps)**, **Azure Key Vault**, and **Cloudflare Tunnels**, this lab bridges the gap between local development and enterprise infrastructure.

*(Note: Earlier iterations of this project relied on local secret files and imperative deployment scripts like `Deploy-Lab.ps1`. We have since migrated fully to GitOps with Flux and centralized secret management with Azure Key Vault. You can safely ignore legacy scripts or local secret placeholders.)*

## 📋 Prerequisites

Before you start, ensure you have the following accounts and CLI tools installed on your Windows machine. **We will be using PowerShell for these steps.**

### Accounts & Services

* **GitHub Account**: To host your repository for Flux GitOps.
* **Azure Account**: With an active subscription for Arc and Key Vault.
* **Cloudflare Account & Domain**: To expose your services securely without port forwarding.

### Command Line Tools (Windows)

Ensure these are in your system PATH:
* **Docker Desktop**: Running and configured for Linux containers (allocate at least 4GB RAM).
* **Kind**: To spin up the local cluster.
* **kubectl**: To interact with the cluster.
* **Helm**: To install Kubernetes packages.
* **Flux CLI**: To bootstrap GitOps (`choco install flux`).
* **Azure CLI (`az`)**: For Azure resource management.

### Azure CLI Extensions

You need specific extensions to connect your local cluster to Azure Arc:

```powershell
az extension add --name connectedk8s
az extension add --name k8s-configuration
```

## 🚀 Step 1: Create the Local Cluster

First, clone this repository to your machine, then spin up the Kind cluster:

```powershell
git clone [https://github.com/jukkamic/enterprise-kubernetes.git](https://github.com/jukkamic/enterprise-kubernetes.git)
cd enterprise-kubernetes

# Create the cluster using our custom config
kind create cluster --name enterprise-cluster --config kind-config.yaml

# Verify connection
kubectl cluster-info --context kind-enterprise-cluster
```

## ☁️ Step 2: Azure Key Vault & Service Principal

Your cluster needs a Key Vault to store secrets and an identity (Service Principal) to read them. Key Vault names must be globally unique, so we'll use a PowerShell trick to generate a random name.

### 1\. Log in and Create Infrastructure

```powershell
az login
# Save your Subscription ID from the output for the next steps!

# Create the Resource Group
az group create --name "Hybrid-Lab" --location "northeurope"

# Generate a random Vault name and create it
$VAULT_NAME = "hobby-vault-$(Get-Random)"
az keyvault create --name $VAULT_NAME --resource-group "Hybrid-Lab" --location "northeurope" --enable-rbac-authorization

Write-Host "Your Key Vault Name is: $VAULT_NAME"
```

**⚠️ Note:** Write down your vault name.

### 2. Create the Service Principal

Create an identity for your Kubernetes cluster to access the Key Vault. Replace `<YOUR_SUBSCRIPTION_ID>` with your actual ID.

```powershell
az ad sp create-for-rbac --name "HobbyLabRobot" `
  --role "Key Vault Secrets User" `
  --scopes "/subscriptions/<YOUR_SUBSCRIPTION_ID>/resourceGroups/Hybrid-Lab/providers/Microsoft.KeyVault/vaults/$VAULT_NAME"
```

> ⚠️ **CRITICAL: SAVE THIS OUTPUT\!**
> The command will output a JSON block. **You must securely save the `appId`, `password`, and `tenant`.** You will need these to configure the Kubernetes CSI driver. If you lose the password, you must reset it.

## 🔗 Step 3: Connect to Azure Arc

Now we project our local Kind cluster into Azure so it can be managed centrally.

```powershell
# Connect the cluster to Azure Arc
az connectedk8s connect --name "hobby-lab" --resource-group "Hybrid-Lab" --location "northeurope"

# If it already exists, you may delete with 
# az connectedk8s delete --name "hobby-lab" --resource-group "Hybrid-Lab" --yes

# Verify the connection in Azure
az connectedk8s show --name "hobby-lab" --resource-group "Hybrid-Lab"
```

## ⚙️ Step 4: Install the Secret Provider CSI Driver

To inject secrets from Key Vault directly into your application pods, install the CSI driver via Helm.

```powershell
# Add the Helm repo and install
helm repo add csi-secrets-store-provider-azure [https://azure.github.io/secrets-store-csi-driver-provider-azure/charts](https://azure.github.io/secrets-store-csi-driver-provider-azure/charts)
helm repo update

helm install csi csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --namespace kube-system
```

Provide the Service Principal credentials (from Step 2) to your cluster:

```powershell
# Replace with your saved App ID and Password
kubectl create secret generic secrets-store-creds `
  --from-literal clientid="<YOUR_APP_ID>" `
  --from-literal clientsecret="<YOUR_PASSWORD>"
```

## 🔄 Step 5: Bootstrap Flux (GitOps) via Azure Arc

Since our cluster is managed by Azure Arc, we will use Azure's managed Flux extension rather than the local CLI. This command installs the Flux agents and points them to our GitHub repository.

```powershell
az k8s-configuration flux create `
  --name hobby-lab-gitops `
  --cluster-name hobby-lab `
  --resource-group "Hybrid-Lab" `
  --cluster-type connectedClusters `
  --scope cluster `
  --namespace flux-system `
  --url [https://github.com/jukkamic/enterprise-kubernetes](https://github.com/jukkamic/enterprise-kubernetes) `
  --branch main `
  --kustomization name=lab-cluster path=./lab-cluster sync_interval=1m `
  --kustomization name=flux-system path=./clusters/hobby-lab/flux-system sync_interval=1m
```
Azure will now quietly install Flux into your cluster and begin syncing your Spring Boot application and configurations.

## 🌐 Step 6: Cloudflare Tunnel Routing

To make your Spring Boot app accessible to the internet:

1.  Authenticate your local cloudflared agent: `cloudflared tunnel login`
2.  Create the tunnel: `cloudflared tunnel create local-k8s-tunnel`
3.  Route your domain: `cloudflared tunnel route dns local-k8s-tunnel myapp.yourdomain.com`
4.  Ensure your Cloudflare secret and deployment YAMLs are pushed to GitHub so Flux can apply them.

## 🚑 Troubleshooting Common Enterprise Lab Issues

* **Check App Deployment:** `kubectl get pods -n default`
* **Check Flux Sync Status:** `flux get kustomizations`
* **Secrets Failing?** If pods are stuck in `ContainerCreating`, double-check that the `tenantId` and `keyvaultName` in your `SecretProviderClass.yaml` match the random `$VAULT_NAME` you generated, and that your Service Principal credentials are correct.
* **SUBSCRIPTION_ID?** ```az account show --query id --output tsv```
  
When combining this many enterprise tools locally, things can occasionally get tangled. Here are the most common issues and how to diagnose them:

### 1. Azure Arc Connection Drops

If the Azure Portal shows your cluster as "Offline", the local Arc agents might have crashed or lost internet access from within your WSL/Docker environment.
* **Check the Arc agents:**
* 
  ```powershell
  kubectl get pods -n azure-arc
  ```
  *Ensure all pods are in a `Running` state. If any are `CrashLoopBackOff` or `Pending`, check their logs (`kubectl logs <pod-name> -n azure-arc`).*

* **Force a sync:** Sometimes, simply deleting the `clusterconnect-agent` pod forces it to recreate and phone home successfully.

### 2. Flux Isn't Syncing Your Changes

You pushed a YAML change to GitHub, but your local cluster isn't updating.
* **Check the overall Flux status:**
  ```powershell
  flux get all
  ```
  *Look for any `Ready` states that say `False` or show a specific error message under the `Message` column.*

* **Check the Flux logs:** This is the best way to see exactly what YAML syntax error or missing reference is blocking the reconciliation:
  ```powershell
  flux logs --level=error --all-namespaces
  ```

### 3. Pods Stuck in `ContainerCreating` (Key Vault Issues)

This is the classic symptom of the CSI driver failing to mount your Azure Key Vault secrets.

* **Inspect the pod events:**
  ```powershell
  kubectl describe pod <your-spring-boot-pod-name>
  ```
  *Scroll down to the `Events` section at the very bottom. You will usually see a detailed error message from the `secrets-store-csi-driver`.*

* **The Usual Suspects:** 
  * Your `appId` or `password` in the `secrets-store-creds` Kubernetes secret is incorrect.
  * The `tenantId` in your `SecretProviderClass.yaml` doesn't match your Azure tenant.
  * The `keyvaultName` in your `SecretProviderClass.yaml` doesn't exactly match the random `$VAULT_NAME` you generated earlier.
  * The Service Principal lacks the "Key Vault Secrets User" role on your new Key Vault.

### 4. Cloudflare Tunnel is Offline (502 Bad Gateway)

Your custom domain is failing to route traffic to your local Spring Boot app.

* **Check the Cloudflare pod logs:**
  ```powershell
  # Find your cloudflared pod (adjust namespace if needed)
  kubectl get pods -l app=cloudflared
  
  # Check the logs for connection errors
  kubectl logs -l app=cloudflared
  ```
  *Look for authentication errors, invalid tunnel tokens, or failures to reach the Cloudflare edge network.*

### 5. Service account token

```powershell
# 1. Create a service account (a user) for the Azure Portal
kubectl create serviceaccount azure-user

# 2. Give that user admin rights to see everything (it's a local lab, so we're keeping it simple)
kubectl create clusterrolebinding azure-user-binding --clusterrole cluster-admin --serviceaccount default:azure-user

# 3. Generate the token (making it valid for a year so you don't have to do this again)
kubectl create token azure-user --duration=8760h
```