# Enterprise Kubernetes Lab: Spring Boot, Azure Arc & PostgreSQL

A corporate-realistic Kubernetes environment designed to bridge local development with enterprise cloud patterns. This project serves as an advanced sandbox to explore Kubernetes (K8s) management, highly-available deployments, hybrid-cloud connectivity, and GitOps secrets management.

## 🏗️ Architecture

* **Local Infrastructure:** [Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) running a multi-node topology (1 Control Plane, 2 Worker Nodes).
* **Cloud Control Plane:** [Azure Arc](https://azure.microsoft.com/en-us/products/azure-arc/) for centralized management, resource inventory, and observability from the cloud.
* **Application Stack:** Java Spring Boot web application (Stateless, running 2 Replicas for High Availability).
* **Data Layer:** Centralized PostgreSQL Database deployed within the cluster to resolve "split-brain" session inconsistencies.
* **Ingress / Network:** [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/) (`cloudflared`) for secure, zero-trust internet access to the local cluster without opening firewall ports.

## 🎯 Project Achievements

1. Provisioned a multi-node local cluster using `kind` to simulate a true distributed environment.
2. Successfully tethered the local cluster to the Azure Cloud using Azure Arc (`connectedk8s`).
3. Containerized a Java Spring Boot application and deployed it across multiple worker nodes.
4. Diagnosed and resolved a "split-brain" application state by migrating from local H2 databases to a centralized, in-cluster PostgreSQL deployment.
5. Secured database credentials using Kubernetes `Secrets` and the GitOps "Split and Ignore" methodology.
6. Implemented Cloudflare Tunnels to securely expose the application to the public internet with automated load-balancing across pods.

## 🚀 Getting Started

### Prerequisites

* Docker Desktop / Rancher Desktop
* [Kind CLI](https://kind.sigs.k8s.io/docs/user/quick-start/)
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* Java 17+ & Maven

### 1. Provision the Infrastructure

Spin up the local multi-node cluster:

```bash
kind create cluster --config kind-config.yaml
```

### 2. Configure Database Secrets (Security First)

To prevent committing plaintext passwords to version control, we use the "Split and Ignore" method. 
Create a file named `postgres-secret.yaml` in the root directory **(Ensure this file is in your `.gitignore`)**:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  POSTGRES_DB: springdb
  POSTGRES_USER: springuser
  POSTGRES_PASSWORD: supersecretpassword
```

Apply the secret to the cluster:

```bash
kubectl apply -f postgres-secret.yaml
```

### 3. Deploy the Data Layer

Deploy the centralized PostgreSQL database and its internal network service:

```bash
kubectl apply -f postgres-infra.yaml
```

### 4. Build and Deploy the Application

Build the Java application and package it into a Docker image:

```bash
mvn clean package
docker build -t spring-webapp:v3 .
```

Sideload the image directly into the `kind` cluster's registry:

```bash
kind load docker-image spring-webapp:v3
```

Deploy the Spring Boot application (2 Replicas):

```bash
kubectl apply -f app-deployment.yaml
```

### 5. Expose via Cloudflare Tunnel (In-Cluster Ingress)

Instead of running a local client, the Cloudflare Zero Trust tunnel is deployed as a native Kubernetes Pod to securely route external traffic to the internal Service without opening local firewall ports:
*(Note: Requires generating a tunnel token via the Cloudflare Dashboard)*

```bash
kubectl apply -f cloudflare-tunnel.yaml
```

### 6. Connect to Azure Arc

Tether the cluster to Azure for enterprise monitoring:

```bash
az connectedk8s connect --name my-enterprise-cluster --resource-group my-resource-group
```

---

## 🛠️ Useful Commands for Debugging

**Check where pods are physically running (Node scheduling):**

```bash
kubectl get pods -o wide
```

**Watch live, aggregated logs across all replicas (Proves load balancing):**

```bash
kubectl logs -f -l app=spring-webapp --prefix
```

**Test High Availability (Chaos Engineering):**

```bash
kubectl delete pod <pod-name>
```

*(Watch Kubernetes instantly spin up a replacement without dropping the application's uptime).*
