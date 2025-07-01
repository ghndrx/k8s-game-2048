#!/bin/bash

# Setup script for Knative Serving installation
# This script installs Knative Serving on a Kubernetes cluster

set -e

echo "🚀 Setting up Knative Serving..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot access Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

# Install Knative Serving CRDs
echo "📦 Installing Knative Serving CRDs..."
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-crds.yaml

# Wait for CRDs to be established
echo "⏳ Waiting for CRDs to be established..."
kubectl wait --for condition=established --timeout=120s crd/configurations.serving.knative.dev
kubectl wait --for condition=established --timeout=120s crd/revisions.serving.knative.dev
kubectl wait --for condition=established --timeout=120s crd/routes.serving.knative.dev
kubectl wait --for condition=established --timeout=120s crd/services.serving.knative.dev

# Install Knative Serving core
echo "📦 Installing Knative Serving core..."
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-core.yaml

# Wait for Knative Serving to be ready
echo "⏳ Waiting for Knative Serving to be ready..."
kubectl wait --for=condition=Ready pod -l app=controller -n knative-serving --timeout=300s
kubectl wait --for=condition=Ready pod -l app=webhook -n knative-serving --timeout=300s

# Install Knative Serving HPA (Horizontal Pod Autoscaler)
echo "📦 Installing Knative Serving HPA..."
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-hpa.yaml

# Configure domain
echo "🌐 Configuring domain..."
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"wa.darknex.us":""}}'

echo "✅ Knative Serving installation completed!"
echo ""
echo "Next steps:"
echo "1. Install Kourier as the networking layer: ./setup-kourier.sh"
echo "2. Configure DNS to point your domain to the Kourier LoadBalancer"
echo "3. Deploy your applications using the manifests in this repository"
