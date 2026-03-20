Here is your official Weekend Warrior Kubernetes Cheat Sheet. Keep this handy so when your friend creates a completely different app to test the scaffolding tools, they can spin up the entire environment and get routing established in under five minutes.

---

### Phase 1: Windows & WSL Prep 
*Run these in your standard Windows PowerShell/CMD terminal to ensure Docker has enough memory and the correct Linux architecture (cgroup v2).*

1. **Edit WSL Config:** `notepad "$env:USERPROFILE\.wslconfig"`
2. **Update WSL Kernel:** `wsl --update`
3. **Hard Reboot WSL:** `wsl --shutdown`

### Phase 2: Build the Bunker
*Make sure Docker Desktop is running before executing these.*

1. **Create the Cluster:** 
   ```bash
   kind create cluster --config kind-config.yaml --name hybrid-lab
   ```
2. **Verify Nodes:** 
   ```bash
   kubectl get nodes
   ```

### Phase 3: Open the Zero Trust Tunnel
*This drops the Cloudflare pod into the cluster to establish the secure outbound connection.*

1. **Deploy Tunnel:**
   ```bash
   kubectl apply -f cloudflare-tunnel.yaml
   ```
2. **Verify Pod Status:**
   ```bash
   kubectl get pods
   ```

### Phase 4: Build & Deploy the Java App
*Run these from the root of your Spring Boot project (`spring-ai-test`).*

1. **Compile the JAR:**
   ```bash
   ./mvnw clean package -DskipTests
   ```
2. **Build the Docker Image:**
   ```bash
   docker build -t spring-webapp:v2 .
   ```
3. **Sideload Image into Cluster:**
   ```bash
   kind load docker-image spring-webapp:v2 --name hybrid-lab
   ```
4. **Deploy Application (from enterprise-kubernetes folder):**
   ```bash
   kubectl apply -f app-deployment.yaml
   ```

### Phase 5: The Nuke (Teardown)
*Run this when you are done working to completely destroy the environment and reclaim your laptop's resources.*

1. **Destroy the Cluster:**
   ```bash
   kind delete cluster --name hybrid-lab
   ```
2. **Reclaim RAM:**
   ```bash
   wsl --shutdown
   ```

---

You have officially conquered Windows networking, Docker limitations, and Kubernetes routing all in one go. 

**Now that your infrastructure is documented and securely torn down, are you ready to close the terminal and enjoy the rest of your Friday night?**