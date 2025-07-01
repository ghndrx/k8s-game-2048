#!/bin/bash

# Setup script for Kourier networking layer
# This script installs Kourier as the Knative networking layer

set -e

echo "🚀 Setting up Kourier networking layer..."

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

# Check if Knative Serving is installed
if ! kubectl get namespace knative-serving &> /dev/null; then
    echo "❌ Knative Serving is not installed. Please run ./setup-knative.sh first."
    exit 1
fi

# Install Kourier
echo "📦 Installing Kourier..."
kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.12.0/kourier.yaml

# Wait for Kourier to be ready
echo "⏳ Waiting for Kourier to be ready..."
kubectl wait --for=condition=Ready pod -l app=3scale-kourier-gateway -n kourier-system --timeout=300s

# Configure Knative to use Kourier
echo "🔧 Configuring Knative to use Kourier..."
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'

# Get the external IP of Kourier
echo "🔍 Getting Kourier LoadBalancer details..."
kubectl get svc kourier -n kourier-system

# Configure auto-TLS (optional)
echo "🔐 Configuring auto-TLS..."
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"autoTLS":"Enabled","httpProtocol":"Redirected"}}'

# Install cert-manager for TLS (optional but recommended)
echo "📦 Installing cert-manager for TLS..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Wait for cert-manager to be ready
echo "⏳ Waiting for cert-manager to be ready..."
kubectl wait --for=condition=Ready pod -l app=cert-manager -n cert-manager --timeout=300s
kubectl wait --for=condition=Ready pod -l app=cainjector -n cert-manager --timeout=300s
kubectl wait --for=condition=Ready pod -l app=webhook -n cert-manager --timeout=300s

# Install Knative cert-manager integration
echo "📦 Installing Knative cert-manager integration..."
kubectl apply -f https://github.com/knative/net-certmanager/releases/download/knative-v1.12.0/release.yaml

# Create ClusterIssuer for Let's Encrypt
echo "🔐 Creating Let's Encrypt ClusterIssuer..."
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@darknex.us
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: kourier.ingress.networking.knative.dev
EOF

# Configure Knative to use the ClusterIssuer
echo "🔧 Configuring Knative to use cert-manager..."
kubectl patch configmap/config-certmanager \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"issuerRef":"kind: ClusterIssuer\nname: letsencrypt-prod"}}'

echo "✅ Kourier setup completed!"
echo ""
echo "🔍 Kourier LoadBalancer service details:"
kubectl get svc kourier -n kourier-system -o wide
echo ""
echo "📋 Next steps:"
echo "1. Configure your DNS to point the following domains to the LoadBalancer IP:"
echo "   - 2048-dev.wa.darknex.us"
echo "   - 2048-staging.wa.darknex.us"
echo "   - 2048.wa.darknex.us"
echo "   - *.wa.darknex.us (wildcard)"
echo ""
echo "2. Deploy your applications:"
echo "   kubectl apply -f manifests/dev/"
echo "   kubectl apply -f manifests/staging/"
echo "   kubectl apply -f manifests/prod/"
