#!/bin/bash

set -e

echo "🔧 Setting up SSL for 2048 Game with Kourier..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster"
    exit 1
fi

print_status "Installing cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

print_status "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=ready pod -l app=cert-manager -n cert-manager --timeout=120s
kubectl wait --for=condition=ready pod -l app=cainjector -n cert-manager --timeout=120s
kubectl wait --for=condition=ready pod -l app=webhook -n cert-manager --timeout=120s

print_status "Applying SSL certificate configuration..."
kubectl apply -f manifests/ssl-certificate.yaml

print_status "Configuring Knative domain..."
kubectl apply -f manifests/knative-domain-config.yaml

print_status "Configuring Kourier for SSL..."
kubectl apply -f manifests/kourier-ssl-config.yaml

print_status "Deploying all environments..."
kubectl apply -f manifests/dev/
kubectl apply -f manifests/staging/
kubectl apply -f manifests/prod/

print_status "Waiting for certificate to be issued..."
echo "This may take a few minutes..."

# Wait for certificate to be ready
timeout=300
counter=0
while [ $counter -lt $timeout ]; do
    if kubectl get certificate darknex-wildcard-cert -n knative-serving -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' | grep -q "True"; then
        print_status "Certificate is ready!"
        break
    fi
    echo -n "."
    sleep 10
    counter=$((counter + 10))
done

if [ $counter -ge $timeout ]; then
    print_warning "Certificate is taking longer than expected to be issued."
    print_warning "You can check the status with: kubectl describe certificate darknex-wildcard-cert -n knative-serving"
fi

print_status "Checking deployment status..."
echo ""
echo "=== Certificate Status ==="
kubectl get certificates -n knative-serving

echo ""
echo "=== Domain Mappings ==="
kubectl get domainmappings --all-namespaces

echo ""
echo "=== Knative Services ==="
kubectl get ksvc --all-namespaces

echo ""
print_status "🎉 SSL setup complete!"
echo ""
echo "Your 2048 game should be accessible at:"
echo "  • Development: https://2048-dev.wa.darknex.us"
echo "  • Staging:     https://2048-staging.wa.darknex.us"
echo "  • Production:  https://2048.wa.darknex.us"
echo ""
echo "To test SSL is working:"
echo "  curl -I https://2048-dev.wa.darknex.us"
echo "  curl -I https://2048-staging.wa.darknex.us"
echo "  curl -I https://2048.wa.darknex.us"
