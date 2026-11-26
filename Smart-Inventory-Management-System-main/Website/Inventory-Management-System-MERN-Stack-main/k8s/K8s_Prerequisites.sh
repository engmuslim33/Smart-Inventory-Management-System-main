#!/usr/bin/env bash
set -euo pipefail

kubectl apply -f \
  https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.37/deploy/local-path-storage.yaml

kubectl rollout status deployment/local-path-provisioner \
  -n local-path-storage \
  --timeout=180s

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --version 4.15.1 \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30080 \
  --set controller.service.nodePorts.https=30443

kubectl rollout status deployment/ingress-nginx-controller \
  -n ingress-nginx \
  --timeout=180s

if ! kubectl top nodes >/dev/null 2>&1; then
  echo "Metrics Server is required before deploying the HPA resources."
  exit 1
fi

kubectl get storageclass
kubectl get ingressclass
