# Environment Configuration

This repository uses environment variables to keep personal information (domains, emails, repository names) out of the public codebase.

## Quick Setup

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your information:**
   ```bash
   nano .env
   ```

3. **Update these key values:**
   - `BASE_DOMAIN` - Your domain (e.g., `example.com`)
   - `GITHUB_REPOSITORY` - Your GitHub repo (e.g., `username/k8s-game-2048`)
   - `CERT_EMAIL` - Your email for SSL certificates
   - `WEBHOOK_SECRET` - Generate with: `openssl rand -hex 32`

## Environment Variables

### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `BASE_DOMAIN` | Your base domain | `example.com` |
| `WEBHOOK_DOMAIN` | Webhook endpoint domain | `webhook.example.com` |
| `GITHUB_REPOSITORY` | Your GitHub repository | `username/k8s-game-2048` |
| `CERT_EMAIL` | Email for SSL certificates | `admin@example.com` |
| `WEBHOOK_SECRET` | Secret for webhook security | Generated 64-char hex |

### Auto-generated Domains

The following domains are automatically generated from `BASE_DOMAIN`:

- **Development**: `2048-dev.{BASE_DOMAIN}`
- **Staging**: `2048-staging.{BASE_DOMAIN}`
- **Production**: `2048.{BASE_DOMAIN}`

### Canonical Knative Domains

- **Dev**: `game-2048-dev.game-2048-dev.dev.{BASE_DOMAIN}`
- **Staging**: `game-2048-staging.game-2048-staging.staging.{BASE_DOMAIN}`
- **Production**: `game-2048-prod.game-2048-prod.{BASE_DOMAIN}`

## Security

- **Never commit `.env`** - It's in `.gitignore` for security
- **Use strong webhook secrets** - Generate with `openssl rand -hex 32`
- **Rotate secrets regularly** - Update webhook secret periodically

## Deployment Scripts

### Setup Webhook Handler
```bash
./scripts/setup-webhook-deployment.sh
```

### Prepare Environment-Specific Manifests
```bash
./scripts/prepare-deployment.sh
```

### Sanitize Repository (for public sharing)
```bash
./scripts/sanitize-repo.sh
```

## GitHub Secrets

After setting up your `.env`, configure these GitHub repository secrets:

1. Go to your repository Settings → Secrets and variables → Actions
2. Add these secrets from your `.env` file:

```
WEBHOOK_SECRET=<from .env>
DEV_WEBHOOK_URL=https://<WEBHOOK_DOMAIN>/webhook/deploy
STAGING_WEBHOOK_URL=https://<WEBHOOK_DOMAIN>/webhook/deploy
PROD_WEBHOOK_URL=https://<WEBHOOK_DOMAIN>/webhook/deploy
KNATIVE_DOMAIN=<BASE_DOMAIN>
```

## Template System

The repository uses a template system to keep personal information secure:

- **`manifests/templates/`** - Sanitized templates with placeholders
- **`manifests/`** - Your actual deployment manifests (gitignored)
- **`.env.example`** - Template for environment configuration

## Development Workflow

1. Clone repository
2. Copy `.env.example` to `.env`
3. Update `.env` with your configuration
4. Run `./scripts/prepare-deployment.sh`
5. Deploy with `./scripts/setup-webhook-deployment.sh`

This ensures your personal information stays private while keeping the codebase shareable.
