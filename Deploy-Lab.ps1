# --- Default Parameters ---
$RG_NAME = "Hybrid-Lab"
$CLUSTER_NAME = "hobby-lab"
$LOCATION = "northeurope"
$GIT_URL = "https://github.com/jukkamic/enterprise-kubernetes.git"
$GIT_BRANCH = "main"

Write-Host "Starting Hybrid-Lab reconstruction..." -ForegroundColor Cyan

# 1. Create the local Kind cluster
$existingClusters = kind get clusters
if ($existingClusters -contains $CLUSTER_NAME) {
    Write-Host "Kind cluster '$CLUSTER_NAME' already exists locally." -ForegroundColor Green
} else {
    Write-Host "Creating Kind cluster..." -ForegroundColor Yellow
    kind create cluster --name $CLUSTER_NAME
}

# 2. Connect to Azure Arc
Write-Host "Connecting to Azure Arc in Resource Group: $RG_NAME..." -ForegroundColor Cyan
az connectedk8s connect `
    --name $CLUSTER_NAME `
    --resource-group $RG_NAME `
    --location $LOCATION

# 3. Install the Flux Extension (The GitOps Brain)
Write-Host "Installing Flux Extension..." -ForegroundColor Cyan
az k8s-extension create `
    --resource-group $RG_NAME `
    --cluster-name $CLUSTER_NAME `
    --cluster-type connectedClusters `
    --extension-type microsoft.flux `
    --name flux-engine

# 4. Install Monitoring Extension
Write-Host "Enabling Cloud Monitoring..." -ForegroundColor Cyan
az k8s-extension create `
    --name azuremonitor-containers `
    --cluster-name $CLUSTER_NAME `
    --resource-group $RG_NAME `
    --cluster-type connectedClusters `
    --extension-type Microsoft.AzureMonitor.Containers

# 5. Create GitOps Configuration
Write-Host "Pointing Arc to your GitHub lab-cluster folder..." -ForegroundColor Cyan
az k8s-configuration flux create `
    --resource-group $RG_NAME `
    --cluster-name $CLUSTER_NAME `
    --cluster-type connectedClusters `
    --name lab-sync `
    --namespace flux-system `
    --url $GIT_URL `
    --branch $GIT_BRANCH `
    --scope cluster `
    --kustomization name=infra path=./lab-cluster prune=true

Write-Host "Lab is ready! Check the Azure Portal to see your Hybrid-Lab status." -ForegroundColor Green
Write-Host "Check your Azure Portal in ~5 mins to see your Spring Boot app and monitoring data." -ForegroundColor White
