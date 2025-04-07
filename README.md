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
curl -L "https://github.com/OpScaleHub/kind/releases/download/stable/wildcard-tls.yaml" | kubectl apply -f -

# deploy CD controller
kubectl create namespace argocd
kubectl --namespace argocd apply -f https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v2.14.8/manifests/core-install.yaml

kubectl wait --namespace argocd        --for=condition=Available deployments --all --timeout=300s
kubectl wait --namespace ingress-nginx --for=condition=Available deployments --all --timeout=300s

# deploy/expose demo application
kubectl create deployment k8s --port=8080 --image=gcr.io/google-samples/node-hello:1.0
kubectl expose deployment k8s --port=8080
#kubectl wait --namespace argocd --for=condition=Available --timeout=5m deployments --all
#kubectl wait --namespace ingress-nginx --for=condition=Available --timeout=5m deployments --all
sleep 60
kubectl create ingress k8s --rule="local.opscale.ir/*=k8s:8080,tls=wildcard-tls-secret" --class=nginx

sleep 5
#http https://whoami.local.gd/
http https://local.opscale.ir
```
