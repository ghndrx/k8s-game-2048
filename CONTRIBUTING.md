# Contributing to K8s Game 2048

Thank you for considering contributing to this project! This guide will help you get started.

## Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/k8s-game-2048.git
   cd k8s-game-2048
   ```

2. **Local Development**
   ```bash
   # Start local development server
   npm start
   # Or with Python
   python3 -m http.server 8080 --directory src
   ```

3. **Build Docker Image**
   ```bash
   npm run build
   # Or
   docker build -t k8s-game-2048 .
   ```

## Git Workflow

We use a GitFlow-inspired workflow:

- **`master`** - Production-ready code, deployed to production automatically
- **`staging`** - Staging branch, deployed to staging environment automatically
- **`develop`** - Development branch, deployed to dev environment automatically  
- **`feature/*`** - Feature branches, create PR to develop
- **`hotfix/*`** - Hotfix branches, create PR to master
- **`release/*`** - Release branches for production deployment

### Branch Protection Rules

- **`master`**: Requires PR review, all checks must pass
- **`staging`**: Requires PR review, all checks must pass
- **`develop`**: Requires PR review, all checks must pass

## Deployment Environments

| Environment | Branch | Domain | Auto-Deploy |
|-------------|--------|---------|------------|
| Development | `develop` | `2048-dev.wa.darknex.us` | ✅ |
| Staging | `staging` | `2048-staging.wa.darknex.us` | ✅ |
| Production | `master` | `2048.wa.darknex.us` | ✅ |

## Making Changes

### For New Features

1. Create a feature branch from `develop`:
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/your-feature-name
   ```

2. Make your changes and commit:
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

3. Push and create a PR to `develop`:
   ```bash
   git push origin feature/your-feature-name
   ```

### For Bug Fixes

1. Create a hotfix branch from `master`:
   ```bash
   git checkout master
   git pull origin master
   git checkout -b hotfix/fix-description
   ```

2. Make your changes and create PR to `master`

## Commit Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

## Testing

### Local Testing
```bash
# Test the game locally
npm start
open http://localhost:8080
```

### Kubernetes Testing
```bash
# Deploy to development environment
kubectl apply -f manifests/dev/

# Check deployment status
kubectl get ksvc -n game-2048-dev

# Test the deployed service
curl -f https://2048-dev.wa.darknex.us/
```

## Code Style

- Use 2 spaces for indentation
- Use meaningful variable and function names
- Add comments for complex logic
- Keep functions small and focused

## Pull Request Process

1. **Title**: Use conventional commit format
2. **Description**: 
   - What changes were made?
   - Why were they made?
   - How to test the changes?
3. **Testing**: Ensure all environments work correctly
4. **Documentation**: Update README if needed

## Release Process

1. Create a release branch from `master`:
   ```bash
   git checkout master
   git pull origin master
   git checkout -b release/v1.1.0
   ```

2. Update version in `package.json`

3. Create PR to `master`

4. After merge, create a GitHub release with tag

5. Production deployment will trigger automatically

## Getting Help

- Open an issue for bugs or feature requests
- Start a discussion for questions
- Check existing issues before creating new ones

## Code of Conduct

Please note that this project is released with a Contributor Code of Conduct. By participating in this project you agree to abide by its terms.
