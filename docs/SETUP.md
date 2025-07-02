# Knative & Kourier Setup Guide

This guide will help you set up Knative Serving with Kourier networking layer on your Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (v1.21+)
- kubectl configured and working
- Cluster admin permissions
- LoadBalancer support (cloud provider or MetalLB)

## Quick Setup

Run the provided scripts in order:

```bash
# 1. Install Knative Serving
./scripts/setup-knative.sh

# 2. Install Kourier networking layer
./scripts/setup-kourier.sh
```

## Manual Setup

If you prefer to install manually:

### 1. Install Knative Serving

```bash
# Install CRDs
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-crds.yaml

# Install core components
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-core.yaml

# Install HPA autoscaler
kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.0/serving-hpa.yaml
```

### 2. Install Kourier

```bash
# Install Kourier
kubectl apply -f https://github.com/knative/net-kourier/releases/download/knative-v1.12.0/kourier.yaml

# Configure Knative to use Kourier
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ingress-class":"kourier.ingress.networking.knative.dev"}}'
```

### 3. Configure Domain

```bash
# Set your custom domain
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch "{\"data\":{\"${KNATIVE_DOMAIN}\":\"\"}}"
```

### 4. Set up TLS (Optional but Recommended)

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Install Knative cert-manager integration
kubectl apply -f https://github.com/knative/net-certmanager/releases/download/knative-v1.12.0/release.yaml

# Create Let's Encrypt ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: ${CERT_EMAIL}
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: kourier.ingress.networking.knative.dev
EOF

# Configure Knative to use cert-manager
kubectl patch configmap/config-certmanager \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"issuerRef":"kind: ClusterIssuer\nname: letsencrypt-prod"}}'

# Enable auto-TLS
kubectl patch configmap/config-network \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"autoTLS":"Enabled","httpProtocol":"Redirected"}}'
```

## DNS Configuration

After installation, configure your DNS to point to the Kourier LoadBalancer:

1. **Get the LoadBalancer IP**:
   ```bash
   kubectl get svc kourier -n kourier-system
   ```

2. **Create DNS records**:
   ```
   ${DEV_DOMAIN}      -> LoadBalancer IP
   ${STAGING_DOMAIN}  -> LoadBalancer IP
   ${PROD_DOMAIN}          -> LoadBalancer IP
   *.${BASE_DOMAIN}             -> LoadBalancer IP (wildcard)
   ```

## Verification

Test your setup:

```bash
# Check Knative Serving
kubectl get pods -n knative-serving

# Check Kourier
kubectl get pods -n kourier-system

# Check cert-manager (if installed)
kubectl get pods -n cert-manager

# Deploy a test service
kubectl apply -f manifests/dev/

# Check service status
kubectl get ksvc -n game-2048-dev
```

## Troubleshooting

### Common Issues

1. **Pods stuck in Pending**:
   - Check node resources: `kubectl describe nodes`
   - Check PVC status: `kubectl get pvc -A`

2. **LoadBalancer IP not assigned**:
   - Ensure your cluster supports LoadBalancer services
   - For local clusters, consider using MetalLB

3. **TLS certificates not issued**:
   - Check cert-manager logs: `kubectl logs -n cert-manager -l app=cert-manager`
   - Verify DNS propagation: `dig ${DEV_DOMAIN}`

4. **Service not accessible**:
   - Check Kourier gateway logs: `kubectl logs -n kourier-system -l app=3scale-kourier-gateway`
   - Verify domain mapping: `kubectl get domainmapping -A`

### Useful Commands

```bash
# Check Knative service status
kubectl get ksvc -A

# Check revisions
kubectl get rev -A

# Check domain mappings
kubectl get domainmapping -A

# Check Kourier configuration
kubectl get svc kourier -n kourier-system -o yaml

# Check Knative configuration
kubectl get cm -n knative-serving

# Debug service logs
kubectl logs -n <namespace> -l serving.knative.dev/service=<service-name>
```

## Advanced Configuration

### Custom Autoscaling

```yaml
# Add to service annotations
autoscaling.knative.dev/minScale: "0"
autoscaling.knative.dev/maxScale: "100"
autoscaling.knative.dev/target: "70"
autoscaling.knative.dev/scaleDownDelay: "30s"
autoscaling.knative.dev/window: "60s"
```

### Traffic Splitting

```yaml
# In Knative Service spec
traffic:
- percent: 90
  revisionName: myapp-00001
- percent: 10
  revisionName: myapp-00002
```

### Custom Resource Limits

```yaml
# In container spec
resources:
  requests:
    cpu: 100m
    memory: 128Mi
  limits:
    cpu: 1000m
    memory: 512Mi
```

## Monitoring

Consider installing these additional tools:

- **Knative Monitoring**: `kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.12.0/monitoring.yaml`
- **Prometheus**: For metrics collection
- **Grafana**: For visualization
- **Jaeger**: For distributed tracing

## Next Steps

1. Deploy the 2048 game: `kubectl apply -f manifests/dev/`
2. Set up monitoring and alerting
3. Configure backup and disaster recovery
4. Implement proper RBAC policies
5. Set up GitOps with ArgoCD or Flux
