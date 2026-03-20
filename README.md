# Hybrid Kubernetes Lab: Spring Boot & Azure Arc Integration

A corporate-realistic Kubernetes environment designed to bridge local development with enterprise cloud patterns. This project serves as a "Weekend Warrior" sandbox to explore Kubernetes (K8s) management, hybrid-cloud connectivity, and GitOps workflows.

## 🏗️ Architecture

- **Local Cluster:** [Kind](https://kind.sigs.k8s.io/) (Kubernetes in Docker) running a multi-node topology.
- **Cloud Control Plane:** [Azure Arc](https://azure.microsoft.com/en-us/products/azure-arc/) for centralized management and observability.
- **Container Registry:** [Azure Container Registry (ACR)](https://azure.microsoft.com/en-us/products/container-registry/) for private image hosting.
- **Application Stack:** Java Spring Boot webapp with custom Actuator health probes.
- **Ingress:** [Cloudflare Tunnel](https://www.cloudflare.com/products/tunnel/) for secure, zero-trust access to the local cluster.

## 🎯 Project Goals

1. [ ] Provision a multi-node local cluster using Kind.
2. [ ] Connect the local cluster to Azure via Azure Arc.
3. [ ] Automate image builds and pushes to Azure ACR via GitHub Actions.
4. [ ] Deploy a Spring Boot app using K8s manifests (Deployments, Services, Secrets).
5. [ ] Implement Cloudflare Tunnels for secure external access.
6. [ ] Configure Prometheus/Grafana or Azure Monitor for cluster health.

## 🚀 Getting Started

### Prerequisites

- Docker Desktop / Rancher Desktop
- [Kind CLI](https://kind.sigs.k8s.io/docs/user/quick-start/)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Java 17+ & Maven

### Local Cluster Setup

```bash
kind create cluster --config kind-config.yaml --name hybrid-lab