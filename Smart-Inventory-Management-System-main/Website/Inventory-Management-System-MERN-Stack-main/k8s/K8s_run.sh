#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="smart-inventory"

kubectl get ingressclass nginx >/dev/null
kubectl get deployment local-path-provisioner -n local-path-storage >/dev/null

kubectl apply -f "$SCRIPT_DIR/00-namespace.yaml"
kubectl apply -f "$SCRIPT_DIR/01-storageclass.yaml"

if ! kubectl get secret ims-secrets -n "$NAMESPACE" >/dev/null 2>&1; then
  JWT_SECRET="$(openssl rand -hex 32)"
  kubectl create secret generic ims-secrets \
    -n "$NAMESPACE" \
    --from-literal=JWT_SECRET="$JWT_SECRET" \
    --from-literal=JWT_EXPIRES_IN="1d"
fi

for manifest in \
  02-mongo.yaml \
  03-auth-service.yaml \
  04-product-service.yaml \
  05-order-service.yaml \
  06-inventory-service.yaml \
  07-statistics-service.yaml \
  08-api-gateway.yaml \
  09-frontend.yaml \
  10-ingress.yaml \
  11-hpa.yaml
do
  kubectl apply -f "$SCRIPT_DIR/$manifest"
done

kubectl scale deployment --all --replicas=1 -n "$NAMESPACE"

for deployment in \
  mongo \
  auth-service \
  product-service \
  order-service \
  inventory-service \
  statistics-service \
  api-gateway \
  frontend
do
  kubectl rollout status deployment/"$deployment" \
    -n "$NAMESPACE" \
    --timeout=180s
done

kubectl get pods,svc,ingress,pvc,hpa -n "$NAMESPACE"
