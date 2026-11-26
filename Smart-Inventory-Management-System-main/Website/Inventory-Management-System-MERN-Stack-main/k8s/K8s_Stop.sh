#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NAMESPACE="smart-inventory"

kubectl delete -f "$SCRIPT_DIR/11-hpa.yaml" --ignore-not-found
kubectl scale deployment --all --replicas=0 -n "$NAMESPACE"

echo "Smart Inventory workloads stopped."
echo "Services, Ingress, PVC, PV, and MongoDB data are preserved."

kubectl get deployments,pvc -n "$NAMESPACE"
