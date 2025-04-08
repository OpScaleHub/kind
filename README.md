# KinD Cluster with GitHub Container Registry Support

A customized KinD (Kubernetes in Docker) configuration with GitHub Container Registry (GHCR) integration, ingress-nginx, and ArgoCD support.

## Architecture Overview

```mermaid
graph TD
    subgraph External
        Client[Client Browser]
        GHCR[GitHub Container Registry]
    end

    subgraph KinD["KinD Cluster"]
        subgraph CP["Control Plane"]
            API[API Server]
            ETCD[(etcd)]
            CM[Controller Manager]
        end

        subgraph Workers["Worker Nodes"]
            W1[Worker 1]
            W2[Worker 2]
        end

        subgraph Components["Core Components"]
            ING[Ingress Controller]
            ARGO[ArgoCD]
            CERT[TLS Certificate]
        end
    end

    Client --> ING
    ING --> API
    API --> ETCD
    API --> W1
    API --> W2
    ARGO --> API
    GHCR --> |Images| CP
    GHCR --> |Images| Workers
```

## Features

- 🔄 Custom node images from GHCR
- 🔐 Automatic TLS certificate management
- 🚀 Pre-configured ingress-nginx controller
- 📦 Built-in ArgoCD for GitOps
- 🔄 Weekly certificate renewal

## Certificate Management

```mermaid
sequenceDiagram
    participant GH as GitHub Action
    participant CB as Certbot
    participant CF as Cloudflare DNS
    participant LE as Let's Encrypt
    participant GR as Github Release

    GH->>CB: Trigger weekly renewal
    CB->>CF: Update DNS records
    CB->>LE: Request certificate
    LE-->>CB: Issue certificate
    CB->>GH: Generate K8S secret
    GH->>GR: Publish/Update TLS cert as GH Release Asset
```

## Deployment Process

```mermaid
stateDiagram-v2
    [*] --> CreateCluster
    CreateCluster --> ConfigureIngress
    ConfigureIngress --> InstallCert
    InstallCert --> DeployArgoCD
    DeployArgoCD --> WaitComponents
    WaitComponents --> Ready
    Ready --> [*]
```

## Network Architecture

```mermaid
flowchart TB
    subgraph Internet
        Client([Client])
        DNS[DNS Service]
    end

    subgraph Docker["Docker Network"]
        subgraph Kind["KinD Cluster Network"]
            ING[Ingress 80/443]
            CP[Control Plane]
            W1[Worker 1]
            W2[Worker 2]
        end
    end

    Client --> |HTTPS| ING
    Client --> |DNS Query| DNS
    DNS --> |Resolves| ING
    ING --> |Routes| CP
    CP --> |Schedules| W1
    CP --> |Schedules| W2
```

## Quick Start

1. **Create the cluster**
```bash
# Get latest stable version
VERSION=$(curl -s "https://raw.githubusercontent.com/OpScaleHub/kind/refs/heads/main/version.txt")

# Create cluster using versioned configuration
curl -L "https://github.com/OpScaleHub/kind/releases/download/v${VERSION}/clusterConfiguration.yaml" | kind create cluster --config -
```

2. **Configure ingress controller**
```bash
# Label the control-plane node
kubectl label nodes kind-control-plane ingress-ready=true

# Deploy ingress-nginx
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml
```

3. **Install TLS certificate**
```bash
# Get latest stable version
VERSION=$(curl -s "https://raw.githubusercontent.com/OpScaleHub/kind/refs/heads/main/version.txt")

# Deploy wildcard TLS certificate for *.local.opscale.ir
curl -L "https://github.com/OpScaleHub/kind/releases/download/v${VERSION}/wildcard-tls.yaml" | kubectl apply -f -
```

4. **Wait for components**
```bash
kubectl wait --timeout=5m --namespace ingress-nginx --for=condition=Available deployments --all
kubectl wait --timeout=5m --namespace ingress-nginx --for=condition=Complete  jobs        --all
kubectl wait --timeout=5m --namespace ingress-nginx --for=condition=Ready     pod --selector app.kubernetes.io/component=controller
```

5. **Deploy ArgoCD**

> [!NOTE]
>
> ArgoCD deployment is optional. You can skip this step if you don't need GitOps capabilities.
>
> If you choose to deploy ArgoCD, it will be installed with default configuration.

```bash
kubectl create namespace argocd
kubectl --namespace argocd apply -f \
  https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v2.14.8/manifests/core-install.yaml
kubectl wait --timeout=5m --namespace argocd        --for=condition=Available deployments --all
```

## Demo Application

```mermaid
graph TD
    subgraph External
        Client[Client Browser]
        DNS[DNS: local.opscale.ir]
    end

    subgraph KinD["KinD Cluster"]
        subgraph Ingress["Ingress Layer"]
            ING[Ingress Controller]
            TLS[Wildcard TLS Certificate]
        end

        subgraph App["Demo Application"]
            SVC[Service: k8s]
            DEP[Deployment: k8s]
            POD[Pod: node-hello]
        end
    end

    Client -->|HTTPS| DNS
    DNS -->|Resolves| ING
    ING -->|TLS Termination| TLS
    ING -->|Route: /*| SVC
    SVC -->|Load Balance| DEP
    DEP -->|Manages| POD
```

Deploy a sample application to verify the setup:

```bash
# Create and expose deployment
kubectl create deployment k8s --port=8080 --image=gcr.io/google-samples/node-hello:1.0
kubectl expose deployment k8s --port=8080

# Configure ingress
kubectl create ingress k8s --rule="local.opscale.ir/*=k8s:8080,tls=wildcard-tls" --class=nginx

# Verify deployment
kubectl wait --for=condition=available --timeout=60s ingress/k8s

# Test the endpoint
curl -k https://local.opscale.ir
```

## Component Versions

- KinD Node Image: `v1.32.3`
- ingress-nginx: `v1.8.2`
- ArgoCD: `v2.14.8`

## Contributing

For bug reports and feature requests, please open an issue in the GitHub repository.
