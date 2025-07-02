# 🚀 Quick Workflow Reference

## 🎯 Common Actions

### Check All Environment Status
```
Actions → Deployment Status Check → Run workflow
```

### Manual Production Deployment
```
Actions → Deploy to Production → Run workflow
↳ Type "DEPLOY" in confirmation
↳ Optional: specify image tag
```

### Manual Production Promotion
```
Actions → Promote to Production → Run workflow  
↳ Type "PROMOTE" in confirmation
↳ Optional: skip tests if staging validated
```

### Test Specific Environment
```
Actions → Smoke Tests → Run workflow
↳ Select environment (dev/staging/prod/all)
```

## 🔄 Automatic Flow

```
develop → build → deploy-dev → test → promote → staging → build → deploy-staging → test → promote → main → deploy-prod
```

## 📋 Workflow Quick Reference

| Workflow | Trigger | Purpose | Manual? |
|----------|---------|---------|---------|
| **Build and Push Container Image** | Push to branches | Build Docker images | ❌ |
| **Deploy to Development** | After build on develop | Deploy to dev environment | ✅ |
| **Smoke Tests** | After deployments | Test deployed environments | ✅ |
| **Auto-Promote Pipeline** | After dev smoke tests pass | Merge develop → staging | ❌ |
| **Deploy to Staging** | Push to staging | Deploy to staging environment | ✅ |
| **Promote to Production** | After staging smoke tests | Merge staging → main | ✅ |
| **Deploy to Production** | Push to main OR manual | Deploy to production | ✅ |
| **Deployment Status Check** | Manual or scheduled | Check all environment health | ✅ |

## 🎮 Environment URLs

- **Dev**: Your configured development domain
- **Staging**: Your configured staging domain
- **Production**: Your configured production domain

## 🏷️ Image Tags

- **Development**: `develop-{commit}` (e.g., `develop-abc1234`)
- **Staging**: `staging-{commit}` (e.g., `staging-def5678`)
- **Production**: `main-{commit}` (e.g., `main-ghi9012`)

## 🔑 Required Confirmations

- **Deploy to Production**: Type `DEPLOY`
- **Promote to Production**: Type `PROMOTE`

## 🆘 Emergency Commands

### Rollback Production
1. Actions → Deploy to Production
2. Specify last known good image tag
3. Type "DEPLOY"

### Force Promotion (Skip Tests)
1. Actions → Promote to Production  
2. Type "PROMOTE"
3. Enable "Skip tests" checkbox

### Check System Health
1. Actions → Deployment Status Check
2. View summary for all environment status

---

💡 **Tip**: Always check "Deployment Status Check" first to see current state of all environments!
