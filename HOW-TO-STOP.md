### 1. Stop the Cluster (Free up RAM)
To gracefully shut down the cluster and immediately free up your memory, just stop the Docker container. For a cluster named `enterprise-cluster`, the container is usually named `enterprise-cluster-control-plane`.

```powershell
docker stop enterprise-cluster-control-plane
```

### 2. Prevent Auto-Restart on Docker Boot
If you restart your computer or Docker Desktop, Docker might try to be "helpful" and spin the cluster back up based on its container restart policies. To stop that behavior and keep it offline until you explicitly want it:

```powershell
docker update --restart=no enterprise-cluster-control-plane
```
*(You only need to run this `update` command once. Docker will remember this policy going forward.)*

### 3. Resume the Cluster Later
When you are ready to dive back into the lab, simply start the container again. Kubernetes is remarkably resilient; the control plane will wake up, Flux will check in with GitHub, Arc will reconnect to Azure, and everything will pick up right where you left off.

```powershell
docker start enterprise-cluster-control-plane
```
*(Note: It might take a minute or two for all the pods to report as `Running` again after a cold start.)*
