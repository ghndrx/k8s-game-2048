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

- **Development**: `https://2048-dev.wa.darknex.us`
- **Staging**: `https://2048-staging.wa.darknex.us`
- **Production**: `https://2048.wa.darknex.us`

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
git clone https://github.com/ghndrx/k8s-game-2048.git
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

## Project Structure

```
k8s-game-2048/
├── README.md
├── Dockerfile
├── .github/
│   └── workflows/
│       ├── deploy-dev.yml
│       ├── deploy-staging.yml
│       └── deploy-prod.yml
├── manifests/
│   ├── dev/
│   │   ├── namespace.yml
│   │   ├── service.yml
│   │   └── domain-mapping.yml
│   ├── staging/
│   │   ├── namespace.yml
│   │   ├── service.yml
│   │   └── domain-mapping.yml
│   └── prod/
│       ├── namespace.yml
│       ├── service.yml
│       └── domain-mapping.yml
├── scripts/
│   ├── setup-knative.sh
│   ├── setup-kourier.sh
│   └── deploy.sh
└── src/
    └── (2048 game files)
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

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
