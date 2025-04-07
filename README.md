# kind
Rebuild Kind with Github image support

node Images Sourced from GHCR.

## Kind cluster setup
howto deploy the kindCluster

```bash
kind create cluster --config ~/Workspaces/github.com/OpScaleHub/kind/clusterConfiguration.yaml
# deploy Ingress controller
kubectl label nodes kind-control-plane ingress-ready=true
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml

# secure valid wildcard tls cert for local development: [ *.local.opscale.ir , local.opscale.ir ]
curl -L "https://github.com/OpScaleHub/kind/releases/download/stable/wildcard-tls.yaml" | kubectl apply -f -

# deploy CD controller
kubectl create namespace argocd
kubectl --namespace argocd apply -f https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v2.14.8/manifests/core-install.yaml

kubectl wait --namespace argocd        --for=condition=Available deployments --all --timeout=300s
kubectl wait --namespace ingress-nginx --for=condition=Available deployments --all --timeout=300s

###################
### Demo time   ###
###################

# Create deployment
kubectl create deployment k8s --port=8080 --image=gcr.io/google-samples/node-hello:1.0

# Wait for deployment to be ready
kubectl rollout status deployment k8s

# Expose deployment
kubectl expose deployment k8s --port=8080

# Create ingress
kubectl create ingress k8s --rule="local.opscale.ir/*=k8s:8080,tls=wildcard-tls-secret" --class=nginx

# Wait for ingress to be available
kubectl wait --for=condition=available --timeout=60s ingress/k8s

# Verify resources
echo "Checking deployment status..."
kubectl get deployment k8s
kubectl rollout status deployment k8s

echo "Checking service status..."
kubectl get service k8s

echo "Checking ingress status..."
kubectl get ingress k8s
kubectl describe ingress k8s

# Make the HTTP call
http https://local.opscale.ir
```
