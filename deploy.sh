#!/bin/bash

set -e # Exit immediately if a command exits with a non-zero status.

# Define the base URL for raw GitHub content
BASE_URL="https://github.com/OpScaleHub/kind"
RAW_BASE_URL="https://raw.githubusercontent.com/OpScaleHub/kind"
INGRESS_BASE_URL="https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind"
ARGOCD_BASE_URL="https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v2.14.8/manifests"

# Check if ARGOCD_ENABLED environment variable is set to "true"
deploy_argocd="${ARGOCD_ENABLED:-false}"

# Get the KIND version
VERSION=$(curl -s "${RAW_BASE_URL}/refs/heads/main/version.txt")
echo "Using KIND version: v${VERSION}"

# Create KIND cluster with configuration
echo "Creating KIND cluster..."
curl -L "${BASE_URL}/releases/download/v${VERSION}/clusterConfiguration.yaml" | kind create cluster --config -
echo "KIND cluster created."

# Label the control plane node
echo "Labeling the control plane node..."
kubectl label nodes kind-control-plane ingress-ready=true
echo "Control plane node labeled."

# Deploy Ingress-Nginx
echo "Deploying Ingress-Nginx..."
kubectl apply -f "${INGRESS_BASE_URL}/deploy.yaml"
echo "Ingress-Nginx deployment started."

# Apply wildcard TLS certificate
echo "Applying wildcard TLS certificate..."
curl -L "${BASE_URL}/releases/download/v${VERSION}/wildcard-tls.yaml" | kubectl apply -f -
echo "Wildcard TLS certificate applied."

# Wait for Ingress-Nginx components to be ready
echo "Waiting for Ingress-Nginx components to be ready..."
kubectl wait --timeout=5m --namespace ingress-nginx --for=condition=Available deployments --all
kubectl wait --timeout=5m --namespace ingress-nginx --for=condition=Complete jobs --all
kubectl wait --timeout=5m --namespace ingress-nginx --for=condition=Ready pod --selector app.kubernetes.io/component=controller
echo "Ingress-Nginx is ready."

# Deploy Argo CD if enabled
if [ "$deploy_argocd" = "true" ]; then
    echo "Deploying Argo CD..."
    echo "Creating Argo CD namespace..."
    kubectl create namespace argocd
    echo "Deploying Argo CD manifests..."
    kubectl --namespace argocd apply -f "${ARGOCD_BASE_URL}/core-install.yaml"
    echo "Argo CD deployment started."
    kubectl wait --timeout=5m --namespace argocd --for=condition=Available deployments --all
    echo "Argo CD is ready."
else
    echo "Skipping Argo CD deployment (ARGOCD_ENABLED is not 'true')."
fi

###################
### Demo time   ###
###################

echo "Starting demo deployment..."

# Create deployment
echo "Creating demo deployment 'k8s'..."
kubectl create deployment k8s --port=80 --image=ghcr.io/opscalehub/kind/whoami:main
echo "Deployment 'k8s' created."

# Wait for deployment to be ready
echo "Waiting for deployment 'k8s' to be ready..."
kubectl rollout status deployment k8s
echo "Deployment 'k8s' is ready."

# Expose deployment
echo "Exposing deployment 'k8s' as a service..."
kubectl expose deployment k8s --port=80
echo "Service 'k8s' created."

# Create ingress
echo "Creating ingress 'k8s'..."
kubectl create ingress k8s --rule="local.opscale.ir/*=k8s:80,tls=wildcard-tls" --class=nginx
echo "Ingress 'k8s' created."

# Wait for deployment to be available
echo "Waiting for deployment 'k8s' to be available..."
kubectl wait --for=condition=available --timeout=60s deployment/k8s
echo "Deployment 'k8s' is available."

# Verify resources
echo ""
echo "--- Checking resources ---"
echo ""
echo "Deployment status:"
kubectl get deployment k8s
kubectl rollout status deployment k8s
echo ""
echo "Service status:"
kubectl get service k8s
echo ""
echo "Ingress status:"
kubectl get ingress k8s
kubectl describe ingress k8s
echo ""

# Make the HTTP call (you might need to set up DNS or use host file for local.opscale.ir)
echo "Attempting to access https://local.opscale.ir..."
curl https://local.opscale.ir

echo ""
echo "--- Demo finished ---"
echo "You might need to configure your local machine's DNS or host file to resolve local.opscale.ir."
echo "To clean up, you can run: kind delete cluster"
