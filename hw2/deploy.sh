#!/bin/bash
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
echo "Starting Deployment"


if ! command -v istioctl >/dev/null 2>&1; then
  echo "istioctl is not installed or not in PATH"
  exit 1
fi

echo "Installing / upgrading Istio control plane..."
istioctl install --set profile=demo -y


kubectl label namespace default istio-injection=enabled --overwrite
kubectl apply -f "$SCRIPT_DIR/k8s/configmap.yaml"

CONFIG_PATCH=$(kubectl get configmap app-config -o yaml | sha256sum | cut -d' ' -f1)
kubectl apply -f "$SCRIPT_DIR/k8s/test-pod.yaml"

sed "s/\${CONFIG_CHECKSUM}/$CONFIG_PATCH/" "$SCRIPT_DIR/k8s/deployment.yaml" | kubectl apply -f -
kubectl apply -f "$SCRIPT_DIR/k8s/service.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/service-headless.yaml"

kubectl apply -f "$SCRIPT_DIR/k8s/daemonset.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/cronjob.yaml"

echo "Applying Istio configurations..."
kubectl apply -f "$SCRIPT_DIR/k8s/istio-gateway.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/virtual-service.yaml"
kubectl apply -f "$SCRIPT_DIR/k8s/destination-rule.yaml"

echo "Waiting for components to be ready"

kubectl wait --for=condition=Ready pod/log-app-test-pod --timeout=60s

kubectl rollout status deployment/log-app-deployment --timeout=180s
kubectl rollout status daemonset/log-agent --timeout=180s || true

echo "System is ready"
kubectl get all