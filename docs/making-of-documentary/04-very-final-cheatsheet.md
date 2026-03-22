## 🚀 The "Phoenix" Recovery Checklist

### Phase 1: The Local Foundation

1.  **Create the Cluster**:
    ```powershell
    kind create cluster --name hobby-lab --config kind-config.yaml
    ```
2.  **Sideload your Image** (Crucial! Do this *before* Flux starts looking for it):
    ```powershell
    kind load docker-image spring-webapp:v3 --name hobby-lab
    ```

### Phase 2: The Azure Bridge

3.  **Install the CSI Driver**:
    ```powershell
    helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
    helm install csi-secrets-store csi-secrets-store-provider-azure/csi-secrets-store-provider-azure --set linux.privileged=true
    ```
4.  **Restore the Secret** (The "Permission Slip"):
    ```powershell
    kubectl create secret generic secrets-store-creds `
      --from-literal=clientid="YOUR_CLIENT_ID" `
      --from-literal=clientsecret="YOUR_CLIENT_SECRET"
    ```

### Phase 3: The GitOps "Brain"

5.  **Bootstrap Flux**:
    Run your `flux bootstrap github` command. This connects the cluster to your repo.
6.  **Point to your Apps**:
    If Flux doesn't auto-detect your folder, run the link command:
    ```powershell
    flux create kustomization lab-apps --source=GitRepository/flux-system --path="./lab-cluster" --prune=true --interval=1m
    ```

### Phase 4: The App "Soul"

7.  **Create the Database**:
    Wait for Postgres to be `Running`, then run:
    ```powershell
    $pgPod = (kubectl get pods -l app=postgres -o name)
    kubectl exec -it $pgPod -- psql -U YOUR_USER -c "CREATE DATABASE springdb;"
    ```

---

## 🕵️ Rules to Never Forget
* **The Tag Rule:** If your YAML says `:v3`, your `kind load` **must** say `:v3`. 
* **The Policy Rule:** Always keep `imagePullPolicy: IfNotPresent` for local images so Kubernetes doesn't try to call Docker Hub.
* **The Secret Rule:** The name `secrets-store-creds` in your `kubectl create secret` command must match the `nodePublishSecretRef` name in your YAMLs exactly.

## Commands forgotten

Replace 'your-key-vault-name' with your actual vault name

```bash
az keyvault secret set --vault-name "your-key-vault-name" --name "TUNNEL_TOKEN" --value "your-actual-token-here"
az keyvault secret set --vault-name "your-key-vault-name" --name "DB_USERNAME" --value "springuser"
az keyvault secret set --vault-name "your-key-vault-name" --name "DB_PASSWORD" --value "your-safe-password"
```

### ## 🏁 The Ultimate Test

If you follow these steps, the "Reconciliation" should happen automatically. Flux will see the files, the CSI driver will grab the secrets from Key Vault, and the apps will start.
