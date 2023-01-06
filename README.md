# kind
Rebuild Kind with Github image support

Source node Images from GHCR.


```bash
cat <<EOF >kind.config
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  image: ghcr.io/opscalehub/kind:v1.25.3
  kubeadmConfigPatches:
  - |
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
- role: worker
  image: ghcr.io/opscalehub/kind:v1.25.3
- role: worker
  image: ghcr.io/opscalehub/kind:v1.25.3
- role: worker
  image: ghcr.io/opscalehub/kind:v1.25.3
EOF

kind create cluster --config=kind.config
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
kubectl wait --namespace ingress-nginx --for=condition=ready pod --selector=app.kubernetes.io/component=controller --timeout=120s
kubectl run whoami --image=docker.io/containous/whoami --port 80 --dry-run=client --output=yaml | kubectl apply -f -
kubectl expose pod whoami --port=80 --dry-run=client --output=yaml | kubectl apply -f -
kubectl create ingress whoami --class=nginx --rule=local.opscale.ir/*=whoami:80 --dry-run=client --output=yaml | kubectl apply -f -
kubectl wait --namespace default --for=condition=ready pod --selector=run=whoami --timeout=120s

sleep 5
http http://whoami.local.gd/
```

