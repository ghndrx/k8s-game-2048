# Webhook-Based Deployment Guide

This guide explains how to set up the webhook-based deployment system for the k8s-game-2048 application, designed to work with k3s clusters behind NAT (no direct API access).

## Overview

The deployment pipeline uses secure webhooks instead of direct kubectl/SSH access, making it perfect for k3s clusters behind NAT or firewall restrictions. Each environment (dev, staging, prod) has its own webhook endpoint that receives deployment instructions and applies them locally.

## Architecture

```
GitHub Actions → HTTPS Webhook → Local Webhook Handler → kubectl apply
```

### Deployment Flow

1. **Development**: Triggered on push to `main`/`master`
2. **Staging**: Auto-promoted from successful dev deployment
3. **Production**: Auto-promoted from successful staging OR manual deployment with confirmation

## Required Secrets

Configure these secrets in your GitHub repository settings:

### GitHub Container Registry
- `GITHUB_TOKEN` - Automatically provided by GitHub Actions

### Webhook Endpoints
- `DEV_WEBHOOK_URL` - Your development webhook endpoint
- `STAGING_WEBHOOK_URL` - Your staging webhook endpoint  
- `PROD_WEBHOOK_URL` - Your production webhook endpoint

### Security
- `WEBHOOK_SECRET` - Shared secret for HMAC signature verification
- `KNATIVE_DOMAIN` - Your Knative cluster domain (e.g., `staging.${BASE_DOMAIN}`)

## Webhook Handler Implementation

You need to implement webhook handlers on your k3s cluster that:

1. **Receive** webhook POST requests with deployment details
2. **Verify** HMAC signatures for security
3. **Pull** the specified Docker image
4. **Apply** Kubernetes manifests
5. **Return** deployment status

### Example Webhook Payload

```json
{
  "environment": "development",
  "image": "ghcr.io/owner/repo:tag",
  "namespace": "game-2048-dev",
  "service_name": "game-2048-dev",
  "deployment_id": "123456-1",
  "commit_sha": "abc123...",
  "triggered_by": "username",
  "timestamp": "2024-01-01T12:00:00Z",
  "auto_promotion": false,
  "deployment_strategy": "rolling" // or "blue-green" for prod
}
```

### Security Headers

The webhook includes these security headers:
- `X-Signature-SHA256`: HMAC-SHA256 signature of the payload
- `X-GitHub-Event`: Always "deployment"
- `X-GitHub-Delivery`: Unique delivery ID

### Sample Webhook Handler (Python Flask)

```python
import hashlib
import hmac
import json
import subprocess
from flask import Flask, request, jsonify

app = Flask(__name__)
WEBHOOK_SECRET = "your-webhook-secret"

def verify_signature(payload, signature):
    expected = hmac.new(
        WEBHOOK_SECRET.encode(),
        payload,
        hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(f"sha256={expected}", signature)

@app.route('/webhook/deploy', methods=['POST'])
def deploy():
    # Verify signature
    signature = request.headers.get('X-Signature-SHA256')
    if not verify_signature(request.data, signature):
        return jsonify({"error": "Invalid signature"}), 401
    
    data = request.json
    image = data['image']
    namespace = data['namespace']
    
    try:
        # Pull image
        subprocess.run(['docker', 'pull', image], check=True)
        
        # Apply manifests
        subprocess.run([
            'kubectl', 'apply', '-f', f'manifests/{data["environment"]}/'
        ], check=True)
        
        # Update image
        subprocess.run([
            'kubectl', 'patch', 'ksvc', data['service_name'],
            '-n', namespace,
            '--type', 'merge',
            '-p', f'{{"spec":{{"template":{{"spec":{{"containers":[{{"image":"{image}","imagePullPolicy":"Always"}}]}}}}}}}}'
        ], check=True)
        
        return jsonify({"status": "success", "deployment_id": data['deployment_id']})
        
    except subprocess.CalledProcessError as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
```

## Deployment Strategies

### Development & Staging
- **Strategy**: Rolling update
- **Traffic**: Immediate 100% switch
- **Verification**: Health check after 30-45 seconds

### Production
- **Strategy**: Blue-Green deployment
- **Traffic Split**: 10% → 50% → 100% over 5 minutes
- **Verification**: Extended health checks and response time validation

## Health Checks

All environments use canonical Knative domains for health checks:
- **Dev**: `https://game-2048-dev.game-2048-dev.{KNATIVE_DOMAIN}`
- **Staging**: `https://game-2048-staging.game-2048-staging.{KNATIVE_DOMAIN}`
- **Prod**: `https://game-2048-prod.game-2048-prod.{KNATIVE_DOMAIN}`

## Auto-Promotion Pipeline

```
Push to main → Dev Deployment → Staging Deployment → Production (manual/auto)
```

### Triggers
- **Dev**: Automatic on code changes
- **Staging**: Automatic on successful dev deployment
- **Prod**: Automatic on successful staging deployment OR manual with confirmation

## Manual Deployment

### Staging
```bash
# Trigger staging deployment manually
gh workflow run deploy-staging.yml -f image_tag=v1.2.3
```

### Production
```bash
# Trigger production deployment (requires confirmation)
gh workflow run deploy-prod.yml -f image_tag=v1.2.3 -f confirmation=DEPLOY
```

## Monitoring & Debugging

### GitHub Actions Logs
- View deployment progress in Actions tab
- Check webhook response codes and payloads
- Monitor health check results

### Cluster-Side Debugging
```bash
# Check webhook handler logs
kubectl logs -n webhook-system deployment/webhook-handler

# Check service status
kubectl get ksvc -n game-2048-dev

# Check recent deployments
kubectl get revisions -n game-2048-dev
```

## Security Considerations

1. **HMAC Verification**: All webhooks are signed with SHA-256 HMAC
2. **HTTPS Only**: All webhook endpoints must use HTTPS
3. **Secret Rotation**: Regularly rotate the `WEBHOOK_SECRET`
4. **Network Security**: Consider IP allowlisting for webhook endpoints
5. **Audit Logging**: Log all deployment requests with timestamps and users

## Troubleshooting

### Common Issues

#### Webhook Timeout
- **Symptom**: HTTP 408 or connection timeout
- **Solution**: Check webhook handler is running and accessible
- **Debug**: Test webhook endpoint manually with curl

#### Signature Verification Failed
- **Symptom**: HTTP 401 from webhook
- **Solution**: Verify `WEBHOOK_SECRET` matches on both sides
- **Debug**: Check HMAC calculation in webhook handler

#### Image Pull Errors
- **Symptom**: Deployment fails after webhook success
- **Solution**: Ensure image exists and registry credentials are configured
- **Debug**: Check `kubectl get events` in the target namespace

#### Health Check Failures
- **Symptom**: Deployment marked as failed despite successful webhook
- **Solution**: Verify Knative domain configuration and service startup time
- **Debug**: Check service logs and Knative serving controller logs

### Manual Recovery

If automated deployment fails, you can deploy manually:

```bash
# Set image and apply manifests
kubectl patch ksvc game-2048-dev -n game-2048-dev \
  --type merge \
  -p '{"spec":{"template":{"spec":{"containers":[{"image":"ghcr.io/owner/repo:tag","imagePullPolicy":"Always"}]}}}}'
```

## Benefits of Webhook-Based Deployment

1. **NAT-Friendly**: Works with k3s clusters behind NAT/firewall
2. **Secure**: HMAC-signed webhooks prevent unauthorized deployments
3. **Scalable**: Can handle multiple clusters and environments
4. **Auditable**: Full deployment history in GitHub Actions
5. **Flexible**: Supports various deployment strategies
6. **Reliable**: Retry logic and health checks ensure successful deployments

## Next Steps

1. Implement webhook handlers for each environment
2. Configure webhook endpoints and secrets
3. Test the deployment pipeline end-to-end
4. Set up monitoring and alerting for webhook handlers
5. Document environment-specific configuration
