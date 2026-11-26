# Smart Inventory Management - Kubernetes

This directory deploys the Smart Inventory microservices on Kubernetes.

## Components

- MongoDB 7 with persistent storage
- Auth, Product, Order, Inventory and Statistics services
- API Gateway
- Nginx Frontend and Ingress
- Horizontal Pod Autoscalers

## Prerequisites

- Kubernetes cluster and kubectl
- Helm 3
- Metrics Server
- Internet access for images and Helm charts

Install cluster prerequisites:

    ./K8s_Prerequisites.sh

This installs Local Path Provisioner and Ingress-NGINX as NodePort without creating an AWS Load Balancer.

## Deploy

    ./K8s_run.sh

Verify the deployment:

    kubectl get pods,svc,ingress,pvc,hpa -n smart-inventory

## Access

The Ingress hostname is `ims.local`. Map a Kubernetes node IP to `ims.local` in the client hosts file, allow TCP port 30080 from the client IP, then open:

    http://ims.local:30080

Test from a cluster node:

    curl -I -H 'Host: ims.local' http://NODE_INTERNAL_IP:30080

## Health and Resources

Backend services use HTTP probes on `/health`. The frontend uses `/`. MongoDB uses TCP port 27017.

Application services request 50m CPU and 64Mi memory, with limits of 250m CPU and 256Mi memory.

MongoDB requests 100m CPU and 128Mi memory, with limits of 500m CPU and 512Mi memory.

## Autoscaling

Stateless services scale between 1 and 3 replicas at 70 percent average CPU utilization.

    kubectl get hpa -n smart-inventory

## Persistent Storage

MongoDB uses the `smart-inventory-storage` StorageClass and `mongo-pvc` with 1Gi capacity and Retain reclaim policy.

## Stop and Start

Stop workloads while preserving services and MongoDB data:

    ./K8s_Stop.sh

Start workloads again:

    ./K8s_run.sh

## Secrets

`01-secret.example` is documentation only. `K8s_run.sh` creates the real `ims-secrets` Secret with a random JWT secret when it is missing.
