#!/bin/bash
set -e

# Webhook-based Deployment Setup Script for k8s-game-2048
echo "🚀 Setting up webhook-based deployment for k8s-game-2048..."

# Load configuration from .env file
if [ -f ".env" ]; then
  echo "📋 Loading configuration from .env file..."
  export $(grep -v '^#' .env | xargs)
else
  echo "⚠️ No .env file found, using defaults"
fi

# Configuration with fallbacks
WEBHOOK_SECRET="${WEBHOOK_SECRET:-$(openssl rand -hex 32)}"
MANIFESTS_PATH="${MANIFESTS_PATH:-/home/administrator/k8s-game-2048/manifests}"
WEBHOOK_DOMAIN="${WEBHOOK_DOMAIN:-webhook.${BASE_DOMAIN}}"
KNATIVE_DOMAIN="${KNATIVE_DOMAIN:-${BASE_DOMAIN}}"
KUBECONFIG_PATH="${KUBECONFIG_PATH:-/etc/rancher/k3s/k3s.yaml}"
DEPLOY_INGRESS="${DEPLOY_INGRESS:-true}"
WEBHOOK_REPLICAS="${WEBHOOK_REPLICAS:-1}"

echo "📋 Configuration:"
echo "  Webhook Secret: ${WEBHOOK_SECRET:0:8}..."
echo "  Manifests Path: $MANIFESTS_PATH"
echo "  Webhook Domain: $WEBHOOK_DOMAIN"
echo "  Knative Domain: $KNATIVE_DOMAIN"
echo "  Deploy Ingress: $DEPLOY_INGRESS"
echo "  Replicas: $WEBHOOK_REPLICAS"

# Step 1: Create webhook system namespace
echo ""
echo "📦 Creating webhook system namespace..."
kubectl create namespace webhook-system --dry-run=client -o yaml | kubectl apply -f -

# Step 2: Create webhook secret
echo "🔐 Creating webhook secret..."
kubectl create secret generic webhook-secret \
  --from-literal=webhook-secret="$WEBHOOK_SECRET" \
  -n webhook-system \
  --dry-run=client -o yaml | kubectl apply -f -

# Step 2.5: Create kubeconfig secret for webhook handler
echo "🔑 Creating kubeconfig secret..."
if [ -f "$KUBECONFIG_PATH" ]; then
  kubectl create secret generic webhook-kubeconfig \
    --from-file=config="$KUBECONFIG_PATH" \
    -n webhook-system \
    --dry-run=client -o yaml | kubectl apply -f -
else
  echo "⚠️ Kubeconfig not found at $KUBECONFIG_PATH"
  echo "Please create the webhook-kubeconfig secret manually:"
  echo "kubectl create secret generic webhook-kubeconfig --from-file=config=~/.kube/config -n webhook-system"
fi

# Step 3: Update webhook handler manifests with correct paths
echo "🔧 Updating webhook handler manifests..."
sed -i "s|/home/administrator/k8s-game-2048/manifests|$MANIFESTS_PATH|g" manifests/webhook/webhook-handler.yaml
sed -i "s|webhook.yourdomain.com|$WEBHOOK_DOMAIN|g" manifests/webhook/webhook-ingress.yaml

# Step 4: Deploy webhook handler script ConfigMap
echo "📜 Deploying webhook handler script..."
kubectl apply -f manifests/webhook/webhook-script-configmap.yaml

# Step 5: Deploy webhook handler
echo "🤖 Deploying webhook handler..."
kubectl apply -f manifests/webhook/webhook-handler.yaml

# Step 6: Deploy ingress (optional)
if [ "$DEPLOY_INGRESS" = "true" ]; then
  echo "🌐 Deploying webhook ingress..."
  kubectl apply -f manifests/webhook/webhook-ingress.yaml
else
  echo "⏭️ Skipping ingress deployment (set DEPLOY_INGRESS=true to enable)"
fi

# Step 7: Wait for deployment to be ready
echo "⏳ Waiting for webhook handler to be ready..."
kubectl wait --for=condition=available deployment/webhook-handler -n webhook-system --timeout=300s

# Step 8: Get service information
echo ""
echo "📊 Webhook handler status:"
kubectl get pods -n webhook-system -l app=webhook-handler

echo ""
echo "🌐 Service endpoints:"
kubectl get svc -n webhook-system

# Step 9: Test webhook handler
echo ""
echo "🧪 Testing webhook handler..."
WEBHOOK_POD=$(kubectl get pods -n webhook-system -l app=webhook-handler -o jsonpath='{.items[0].metadata.name}')
if [ -n "$WEBHOOK_POD" ]; then
  echo "Testing health endpoint..."
  kubectl port-forward -n webhook-system pod/$WEBHOOK_POD 8080:8080 &
  KUBECTL_PID=$!
  sleep 5
  
  if curl -s http://localhost:8080/health | grep -q "healthy"; then
    echo "✅ Webhook handler health check passed!"
  else
    echo "⚠️ Webhook handler health check failed"
  fi
  
  kill $KUBECTL_PID 2>/dev/null || true
fi

# Step 10: Display setup information
echo ""
echo "🎉 Webhook-based deployment setup completed!"
echo ""
echo "📝 Next steps:"
echo "1. Configure GitHub repository secrets:"
echo "   - WEBHOOK_SECRET: $WEBHOOK_SECRET"
echo "   - DEV_WEBHOOK_URL: https://$WEBHOOK_DOMAIN/webhook/deploy"
echo "   - STAGING_WEBHOOK_URL: https://$WEBHOOK_DOMAIN/webhook/deploy"
echo "   - PROD_WEBHOOK_URL: https://$WEBHOOK_DOMAIN/webhook/deploy"
echo "   - KNATIVE_DOMAIN: $KNATIVE_DOMAIN"
echo ""
echo "2. Expose webhook handler externally:"
if [ "$DEPLOY_INGRESS" != "true" ]; then
  echo "   # Option A: Use port-forward for testing"
  echo "   kubectl port-forward -n webhook-system svc/webhook-handler-external 8080:80"
  echo ""
  echo "   # Option B: Get LoadBalancer IP (if available)"
  echo "   kubectl get svc webhook-handler-external -n webhook-system"
  echo ""
  echo "   # Option C: Deploy ingress with your domain"
  echo "   DEPLOY_INGRESS=true WEBHOOK_DOMAIN=your-domain.com ./scripts/setup-webhook-deployment.sh"
fi
echo ""
echo "3. Test webhook endpoint:"
echo "   curl -X POST https://$WEBHOOK_DOMAIN/webhook/deploy \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -H 'X-Signature-SHA256: sha256=SIGNATURE' \\"
echo "     -d '{\"environment\":\"dev\",\"image\":\"nginx:latest\",\"namespace\":\"default\",\"service_name\":\"test\"}'"
echo ""
echo "4. Push code changes to trigger automated deployment!"

# Output webhook secret for GitHub configuration
echo ""
echo "🔑 GitHub Secrets Configuration:"
echo "===============================|"
echo "SECRET NAME     | SECRET VALUE"
echo "===============================|"
echo "WEBHOOK_SECRET  | $WEBHOOK_SECRET"
echo "DEV_WEBHOOK_URL | https://$WEBHOOK_DOMAIN/webhook/deploy"
echo "STAGING_WEBHOOK_URL | https://$WEBHOOK_DOMAIN/webhook/deploy"
echo "PROD_WEBHOOK_URL | https://$WEBHOOK_DOMAIN/webhook/deploy"
echo "KNATIVE_DOMAIN  | $KNATIVE_DOMAIN"
echo "===============================|"
