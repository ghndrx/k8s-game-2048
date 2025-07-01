#!/bin/bash

# Deployment script for 2048 game with Istio + nginx SSL setup
# Usage: ./deploy.sh [env] where env = dev|staging|prod|all

set -e

ENVIRONMENT=${1:-all}
REGISTRY="ghcr.io/ghndrx/k8s-game-2048"

echo "🚀 Deploying 2048 game with Istio + nginx SSL..."
echo "Environment: $ENVIRONMENT"

# Validate environment
case $ENVIRONMENT in
    dev|staging|prod|all)
        echo "✅ Valid environment: $ENVIRONMENT"
        ;;
    *)
        echo "❌ Invalid environment. Use: dev, staging, prod, or all"
        exit 1
        ;;
esac

# Check dependencies
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot access Kubernetes cluster"
    exit 1
fi

# Deploy function for a single environment
deploy_env() {
    local env=$1
    echo "📦 Deploying $env environment..."
    
    # Apply namespace
    kubectl apply -f manifests/$env/namespace.yml
    
    # Ensure GHCR secret exists in the namespace
    echo "🔐 Setting up GHCR secret for $env..."
    if kubectl get secret ghcr-secret -n default &>/dev/null; then
        kubectl get secret ghcr-secret -o yaml | \
        sed "s/namespace: default/namespace: game-2048-$env/" | \
        sed '/resourceVersion:/d' | \
        sed '/uid:/d' | \
        sed '/creationTimestamp:/d' | \
        kubectl apply -f -
    else
        echo "⚠️  Warning: No GHCR secret found in default namespace"
    fi
    
    # Apply service
    kubectl apply -f manifests/$env/service.yml
    
    # Wait for service to be ready
    echo "⏳ Waiting for $env service to be ready..."
    kubectl wait --for=condition=Ready ksvc/game-2048-$env -n game-2048-$env --timeout=300s || echo "Warning: Service may still be starting"
}

# Deploy infrastructure (certificates, gateways, etc.)
echo "🏗️  Setting up infrastructure..."
kubectl apply -f manifests/ssl-certificate.yaml
kubectl apply -f manifests/nginx-certificate.yaml
kubectl apply -f manifests/knative-domain-config.yaml
kubectl apply -f manifests/istio-gateway.yaml
kubectl apply -f manifests/nginx-to-istio-proxy.yaml

# Deploy environments
if [ "$ENVIRONMENT" = "all" ]; then
    deploy_env "dev"
    deploy_env "staging" 
    deploy_env "prod"
else
    deploy_env "$ENVIRONMENT"
fi

echo ""
echo "✅ Deployment completed!"
echo ""
echo "� Your 2048 game is available at:"
if [ "$ENVIRONMENT" = "all" ] || [ "$ENVIRONMENT" = "dev" ]; then
    echo "   Development:  https://2048-dev.wa.darknex.us"
fi
if [ "$ENVIRONMENT" = "all" ] || [ "$ENVIRONMENT" = "staging" ]; then
    echo "   Staging:      https://2048-staging.wa.darknex.us"
fi
if [ "$ENVIRONMENT" = "all" ] || [ "$ENVIRONMENT" = "prod" ]; then
    echo "   Production:   https://2048.wa.darknex.us"
fi
echo ""
echo "🔧 Check status with:"
echo "   kubectl get ksvc -A"
echo "   kubectl get certificates -A"
echo "   kubectl get ingress -A"
echo ""
echo "📝 Architecture: Internet → nginx (SSL) → Istio → Knative"
