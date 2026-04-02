#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "Starting Deployment"

kubectl apply -f "$SCRIPT_DIR/k8s/configmap.yaml"

CONFIG_PATCH=$(kubectl get configmap app-config -o yaml | sha256sum | cut -d' ' -f1)
kubectl apply -f "$SCRIPT_DIR/k8s/test-pod.yaml"

sed "s/\${CONFIG_CHECKSUM}/$CONFIG_PATCH/" "$SCRIPT_DIR/k8s/deployment.yaml" | kubectl apply -f -
kubectl apply -f "$SCRIPT_DIR/k8s/service.yaml"

kubectl apply -f "$SCRIPT_DIR/k8s/daemonset.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/cronjob.yaml"

echo "Waiting for deployment..."
kubectl rollout status deployment/log-app-deployment --timeout=180s

echo "Waiting for daemonset..."
kubectl rollout status daemonset/log-agent --timeout=180s || true

echo "System is ready"
kubectl get all