#!/bin/bash

# Deployment script for 2048 game environments
# Usage: ./deploy.sh [dev|staging|prod] [image-tag]

set -e

ENVIRONMENT=${1:-dev}
IMAGE_TAG=${2:-latest}
REGISTRY="ghcr.io/ghndrx/k8s-game-2048"

echo "🚀 Deploying 2048 game to $ENVIRONMENT environment..."

# Validate environment
case $ENVIRONMENT in
    dev|staging|prod)
        echo "✅ Valid environment: $ENVIRONMENT"
        ;;
    *)
        echo "❌ Invalid environment. Use: dev, staging, or prod"
        exit 1
        ;;
esac

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

# Update image tag in manifests
echo "🔧 Updating image tag to $IMAGE_TAG..."
if [ "$ENVIRONMENT" = "dev" ]; then
    sed -i.bak "s|your-registry/game-2048:latest|$REGISTRY:$IMAGE_TAG|g" manifests/dev/service.yml
elif [ "$ENVIRONMENT" = "staging" ]; then
    sed -i.bak "s|your-registry/game-2048:staging|$REGISTRY:$IMAGE_TAG|g" manifests/staging/service.yml
else
    sed -i.bak "s|your-registry/game-2048:v1.0.0|$REGISTRY:$IMAGE_TAG|g" manifests/prod/service.yml
fi

# Deploy to the specified environment
echo "📦 Deploying to $ENVIRONMENT..."
kubectl apply -f manifests/$ENVIRONMENT/

# Wait for deployment to be ready
echo "⏳ Waiting for deployment to be ready..."
kubectl wait --for=condition=Ready ksvc/game-2048-$ENVIRONMENT -n game-2048-$ENVIRONMENT --timeout=300s

# Get service details
echo "✅ Deployment completed!"
echo ""
echo "🔍 Service details:"
kubectl get ksvc game-2048-$ENVIRONMENT -n game-2048-$ENVIRONMENT -o wide

echo ""
echo "🌐 Service URL:"
kubectl get ksvc game-2048-$ENVIRONMENT -n game-2048-$ENVIRONMENT -o jsonpath='{.status.url}'
echo ""

echo ""
echo "🎯 Custom domain:"
case $ENVIRONMENT in
    dev)
        echo "https://2048-dev.wa.darknex.us"
        ;;
    staging)
        echo "https://2048-staging.wa.darknex.us"
        ;;
    prod)
        echo "https://2048.wa.darknex.us"
        ;;
esac

# Restore original manifests
echo "🔄 Restoring original manifests..."
if [ -f "manifests/$ENVIRONMENT/service.yml.bak" ]; then
    mv manifests/$ENVIRONMENT/service.yml.bak manifests/$ENVIRONMENT/service.yml
fi

echo ""
echo "🎮 Game deployed successfully! You can now access it at the custom domain."
