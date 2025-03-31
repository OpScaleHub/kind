# kind
Rebuild Kind with Github image support

node Images Sourced from GHCR.

## Kind cluster setup
howto deploy the kindCluster

update `~/.bashrc` with a function

```
function kindUp {
  kind create cluster --config ~/Workspaces/github.com/OpScaleHub/kind/clusterConfiguration.yaml
  kubectl label nodes kind-control-plane ingress-ready=true
  kubectl create namespace argocd
  kubectl --namespace argocd apply -f https://raw.githubusercontent.com/argoproj/argo-cd/refs/tags/v2.14.8/manifests/core-install.yaml
  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/kind/deploy.yaml
  kubectl apply -f ~/Workspaces/github.com/OpScaleHub/kind/certbotJob.yaml
  #######
  kubectl create deployment k8s --port=8080 --image=gcr.io/google-samples/node-hello:1.0
  kubectl expose deployment k8s --port=8080
  #kubectl wait --namespace argocd --for=condition=Available --timeout=5m deployments --all
  #kubectl wait --namespace ingress-nginx --for=condition=Available --timeout=5m deployments --all
  sleep 60
  kubectl create ingress k8s --rule="local.opscale.ir/*=k8s:8080,tls=wildcard-tls-secret" --class=nginx

  sleep 5
  #http https://whoami.local.gd/
  http https://local.opscale.ir
}
```
