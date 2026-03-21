# Creating this project

This is a documentary of how this project was made on a Windows 11 home computer. 

Some steps require creating config files which are found in this Git repository and are not mentioned separately in this document.

## Requirements

* Docker Desktop
* Go 1.17+
* Kind & Kubectl <https://kind.sigs.k8s.io/>
* Azure CLI
* A domain address

## Phase 1: The Local "Data Center"

Create a Multi-Node Cluster:
A single node isn't "corporate." Create a config file kind-config.yaml:

```powershell
kind create cluster --config kind-config.yaml
```

## Phase 2: The Azure "Control Plane" (The Budget Strategy)

Instead of a full-managed cluster (AKS), which costs money every hour, we will use Azure Arc. This is 100% corporate and mostly free for basic management.

The Registry (ACR): This is your private "Docker Hub."

Create an Azure Container Registry (Basic Tier). It costs pennies a month.

Goal: Your Spring Boot app should be built locally (or via GitHub Actions) and pushed here.

Azure Arc Connection:

Install the connectedk8s extension in your Azure CLI.

Run: az connectedk8s connect --name HomeCluster --resource-group MyK8sGroup

The Result: Go to the Azure Portal. You will see "HomeCluster" listed as a resource. You can now view your local namespaces and pods from the cloud.

## Phase 3: The Java Spring Boot "Enterprise" Check

* Made sure the spring-boot-starter-actuator is included in pom.xml
* Refactored DB connection strings to use ${DB_PASSWORD} environment variables.

## Phase 4: Connecting the Domain (Cloudflare)

Followed these instructions from Gemini:

> Since you have a Cloudflare domain, we can bypass complex Azure networking.
> 
> Cloudflare Tunnel: Run the cloudflared container inside your Kind cluster as a deployment.
> 
> Zero Trust: Map spring-app.yourdomain.com directly to your internal K8s service. No ports to open, no cost for static IPs.

I had to create an account in Cloudflare, add Zerotrust (chose the free plan when prompted), named it ```scaffoldkit```, then created a tunnel and named it ```weekend-warrior-lab```.

Cloudflare guided me to download something and run an installer. I ***saved the given token*** (offline). Running  ```cloudflared.exe service install <token>``` is not needed because the tunnel will run as a container inside the cluster, not as a service on the underlying bare-metal server.

```powershell
kind create cluster --config kind-config.yaml --name hybrid-lab
```
While the cluster is being created run export config and check the status

```powershell
kind export kubeconfig --name hybrid-lab
kubectl get nodes
```

### Problems so far

Creating the cluster runs into resource problems. Had to create ```$env:USERPROFILE\.wslconfig``` with 

```ini
[wsl2]
memory=8GB
processors=4
kernelCommandLine=cgroup_no_v1=all
```

It tells the WSL kernel: "Do not load v1 under any circumstances."

Then kill all Docker processes and run ```wsl --update``` and ```wsl --shutdown``` and wait 10 seconds before restarting WSL before restarting Docker.

```powershell
kind delete cluster --name hybrid-lab
kind create cluster --config kind-config.yaml --name hybrid-lab
```

## Phase 5: Creating the Cloudflare tunnel

create cloudflare-tunnel.yaml from the .example file. Then apply the tunnel.

```powershell
kubectl apply -f cloudflare-tunnel.yaml
```

## Phase 6: The Spring Webapp

Created Dockerfile and ran 

```powershell
docker build -t spring-webapp:v1 .
kind load docker-image spring-webapp:v1 --name hybrid-lab
```

Created app-deployment.yaml.

```powershell
kubectl apply -f app-deployment.yaml
```

### Problems

```powershell
kubectl get pods
kubectl logs spring-webapp-678669b6b-2tf68
```

## Phase 7: Cloudflare and the published route

From Zero Trust, choose Networks -> Routes and publish the service with type HTTP and URL spring-boot-service.default.svc.cluster.local:9443

## And we're done!

<https://ledger.scaffoldkit.dev/>

## Turning it off

**Option 1: The "Pause" Button (Keeps everything intact)**

1. Right-click the Docker whale icon in your Windows system tray.

2. Click Quit Docker Desktop.

3. Open your VSCode Windows terminal and run: wsl --shutdown
This instantly kills the Linux virtual machine and hands the 8GB of RAM back to Windows. When you open Docker Desktop again tomorrow, your cluster and pods will automatically wake back up.

**Option 2: The "Nuke" Button (Destroys the cluster)**

1. Run kind delete cluster --name hybrid-lab
   
This wipes out the cluster, the pods, and the tunnel. When your friend creates that completely different app to test the scaffolding tools later, you can just run your kind create and kubectl apply commands to build a fresh bunker in about 60 seconds.

