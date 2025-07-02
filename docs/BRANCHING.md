# Branch Strategy & Deployment Flow

## Branch Structure

```
master (production)
├── staging (staging environment)
└── develop (development environment)
    ├── feature/feature-name
    ├── feature/another-feature
    └── hotfix/urgent-fix
```

## Deployment Flow

### 🟢 Development Environment
- **Branch**: `develop`
- **Domain**: `${DEV_DOMAIN}`
- **Trigger**: Push to `develop` branch
- **Auto-deploy**: ✅ Yes
- **Purpose**: Latest development features, may be unstable

### 🟡 Staging Environment  
- **Branch**: `staging`
- **Domain**: `${STAGING_DOMAIN}`
- **Trigger**: Push to `staging` branch
- **Auto-deploy**: ✅ Yes
- **Purpose**: Pre-production testing, stable features

### 🔴 Production Environment
- **Branch**: `master`
- **Domain**: `${PROD_DOMAIN}`
- **Trigger**: Push to `master` branch OR GitHub Release
- **Auto-deploy**: ✅ Yes
- **Purpose**: Live production environment

## Workflow Examples

### Adding a New Feature

```bash
# 1. Start from develop
git checkout develop
git pull origin develop

# 2. Create feature branch
git checkout -b feature/awesome-new-feature

# 3. Make changes and commit
git add .
git commit -m "feat: add awesome new feature"

# 4. Push and create PR to develop
git push origin feature/awesome-new-feature
# Create PR: feature/awesome-new-feature → develop
```

### Promoting to Staging

```bash
# 1. Merge feature to develop (via PR)
# 2. Test in dev environment: ${DEV_DOMAIN}

# 3. Promote to staging
git checkout staging
git pull origin staging
git merge develop
git push origin staging

# 4. Test in staging: ${STAGING_DOMAIN}
```

### Deploying to Production

```bash
# 1. After staging testing passes
git checkout master
git pull origin master
git merge staging
git push origin master

# 2. Optionally create a release tag
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# 3. Production deploys automatically: ${PROD_DOMAIN}
```

### Hotfix Flow

```bash
# 1. Create hotfix from master
git checkout master
git pull origin master
git checkout -b hotfix/critical-bug-fix

# 2. Fix the issue
git add .
git commit -m "fix: resolve critical bug"

# 3. Push and create PR to master
git push origin hotfix/critical-bug-fix
# Create PR: hotfix/critical-bug-fix → master

# 4. After merge, also merge back to develop
git checkout develop
git merge master
git push origin develop
```

## CI/CD Pipeline

### Development Pipeline (`develop` branch)
1. ✅ Build Docker image
2. ✅ Push to GHCR with `develop-{sha}` tag
3. ✅ Deploy to dev namespace
4. ✅ Run basic health checks

### Staging Pipeline (`staging` branch)  
1. ✅ Build Docker image
2. ✅ Push to GHCR with `staging-{sha}` tag
3. ✅ Deploy to staging namespace
4. ✅ Run smoke tests
5. ✅ Health check staging URL

### Production Pipeline (`master` branch)
1. ✅ Build Docker image
2. ✅ Push to GHCR with version tag
3. ✅ Blue-green deployment to production
4. ✅ Gradual traffic shifting (10% → 50% → 100%)
5. ✅ Production health checks
6. ✅ Rollback capability

## Environment Configuration

| Environment | Namespace | Min Scale | Max Scale | Scale Down Delay |
|-------------|-----------|-----------|-----------|------------------|
| Development | `game-2048-dev` | 0 | 10 | 30s |
| Staging | `game-2048-staging` | 0 | 20 | 60s |
| Production | `game-2048-prod` | 0 | 50 | 300s |

## Monitoring & Alerts

- **Development**: Basic logging, fast iteration
- **Staging**: Full monitoring, performance testing
- **Production**: Full observability, alerting, SLA monitoring

## Security

- All images are scanned for vulnerabilities
- Secrets managed via GitHub Secrets
- RBAC configured per namespace
- TLS termination at Kourier gateway
- Auto-TLS via cert-manager and Let's Encrypt
