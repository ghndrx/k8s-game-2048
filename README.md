# K8s Game 2048

A Kubernetes deployment of the classic 2048 game using Knative Serving with Istio service mesh and nginx ingress for SSL termination.

## Features

- **Knative Serving**: Serverless deployment with scale-to-zero capability
- **Istio Service Mesh**: Advanced traffic management and observability
- **nginx Ingress**: SSL termination and traffic routing
- **Multi-environment**: Development, Staging, and Production deployments
- **Custom Domains with SSL**: Environment-specific HTTPS domains
- **GitOps Workflow**: Complete CI/CD pipeline with GitHub Actions

## Environments

- **Development**: `https://${DEV_CANONICAL_DOMAIN}`
- **Staging**: `https://${STAGING_CANONICAL_DOMAIN}`
- **Production**: `https://${PROD_CANONICAL_DOMAIN}`

## 🔄 CI/CD Pipeline

This project features a fully automated CI/CD pipeline with:

- **Automated Deployments**: Push to `develop` → auto-deploy to dev → auto-promote to staging → auto-promote to production
- **Comprehensive Testing**: Smoke tests after each deployment
- **Manual Controls**: Override any step with manual workflows
- **Zero-downtime Deployments**: Blue-green strategy for production
- **Security**: Webhook signature validation and environment-specific secrets

### Quick Actions

| Action | Command |
|--------|---------|
| 📊 Check Status | Actions → "Deployment Status Check" |
| 🚀 Deploy to Prod | Actions → "Deploy to Production" (type "DEPLOY") |
| ⬆️ Promote to Prod | Actions → "Promote to Production" (type "PROMOTE") |
| 🧪 Run Tests | Actions → "Smoke Tests" |

📚 **[Full Pipeline Documentation](docs/WORKFLOWS.md)** | 🚀 **[Quick Reference](docs/WORKFLOW_QUICK_REFERENCE.md)**

## Architecture

```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Internet  │    │   nginx     │    │   Istio     │    │   Knative   │
│             │───▶│   Ingress   │───▶│   Gateway   │───▶│   Service   │
│             │    │ (SSL Term.) │    │             │    │             │
└─────────────┘    └─────────────┘    └─────────────┘    └─────────────┘
                           │                                     │
                           ▼                                     ▼
                   ┌─────────────┐                      ┌─────────────┐
                   │ cert-manager│                      │ 2048 Game   │
                   │ Let's Encrypt│                      │ Container   │
                   └─────────────┘                      └─────────────┘
```

## Quick Start

### Prerequisites

- Kubernetes cluster (1.21+) with k3s or similar
- Knative Serving installed
- Istio service mesh installed  
- nginx ingress controller installed
- cert-manager for SSL certificates
- kubectl configured
- Domain DNS configured to point to your cluster IP

### Installation

1. Clone the repository:
```bash
git clone https://github.com/${GITHUB_REPOSITORY}.git
cd k8s-game-2048
```

2. Deploy all environments:
```bash
./scripts/deploy.sh all
```

3. Or deploy a specific environment:
```bash
./scripts/deploy.sh dev     # Development only
./scripts/deploy.sh staging # Staging only  
./scripts/deploy.sh prod    # Production only
```

3. Deploy to staging:
```bash
kubectl apply -f manifests/staging/
```

4. Deploy to production:
```bash
kubectl apply -f manifests/prod/
```

## 📁 Project Structure

```
k8s-game-2048/
├── README.md
├── Dockerfile
├── .github/
│   └── workflows/                    # CI/CD Pipeline
│       ├── build-image.yml          # Build & push Docker images
│       ├── deploy-dev.yml           # Development deployment
│       ├── deploy-staging.yml       # Staging deployment  
│       ├── deploy-prod.yml          # Production deployment
│       ├── smoke-test.yml           # Post-deployment testing
│       ├── auto-promote.yml         # Auto dev → staging promotion
│       ├── promote-to-production.yml # Auto/manual staging → prod
│       └── deployment-status.yml    # Environment health checks
├── docs/
│   ├── WORKFLOWS.md                 # Complete pipeline documentation
│   ├── WORKFLOW_QUICK_REFERENCE.md  # Quick action guide
│   ├── SETUP.md                     # Environment setup guide
│   ├── ENVIRONMENT.md               # Environment configuration
│   └── WEBHOOK_DEPLOYMENT.md        # Webhook handler setup
├── manifests/
│   ├── dev/                         # Development Kubernetes manifests
│   ├── staging/                     # Staging Kubernetes manifests
│   ├── prod/                        # Production Kubernetes manifests
│   └── webhook/                     # Webhook handler manifests
├── scripts/                         # Setup and deployment scripts
└── src/                            # 2048 game source code
    ├── index.html
    ├── style.css
    └── script.js
```

## Deployment

The application uses Knative Serving with the following features:

- **Scale to Zero**: Automatically scales down to 0 when not in use
- **Auto-scaling**: Scales up based on incoming requests
- **Blue-Green Deployments**: Safe deployment strategy with traffic splitting
- **Custom Domains**: Environment-specific domain mapping

## Monitoring

Each environment includes:

- Knative Service status monitoring
- Request metrics via Knative
- Custom domain health checks

## 🔒 Security & Privacy

This repository is **PII-free** and production-ready:

- ✅ **No hardcoded emails, domains, or personal information**
- ✅ **All configuration via environment variables**
- ✅ **Secrets managed via `.env` files and GitHub secrets**
- ✅ **Generic templates that work for any domain/organization**

### Quick Setup

1. **Clone and configure:**
   ```bash
   git clone https://github.com/${GITHUB_REPOSITORY}.git
   cd k8s-game-2048
   cp .env.example .env
   # Edit .env with your actual values
   ```

2. **Apply your configuration:**
   ```bash
   ./scripts/cleanup-pii.sh
   ```

3. **Set GitHub secrets for CI/CD:**
   - `DEV_DOMAIN`, `STAGING_DOMAIN`, `PROD_DOMAIN`
   - `WEBHOOK_SECRET`
   - Webhook URLs for each environment

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
