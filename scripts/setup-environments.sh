#!/bin/bash

# Setup GitHub Environments for Protection Rules
# This script documents the manual steps needed in GitHub UI

echo "🔧 Setting up GitHub Environments for Auto-Promotion Pipeline"
echo ""
echo "📋 Manual Steps Required in GitHub Repository Settings:"
echo ""
echo "1. Go to Settings → Environments"
echo "2. Create 'production-approval' environment"
echo "3. Add required reviewers (yourself)"
echo "4. Set deployment protection rules"
echo ""
echo "Environment Configuration:"
echo "- Environment Name: production-approval"
echo "- Required Reviewers: Repository admins"
echo "- Wait Timer: 0 minutes (immediate on approval)"
echo "- Deployment Branches: main branch only"
echo ""
echo "This ensures production deployments require manual approval"
echo "while dev → staging promotion happens automatically on successful tests."
echo ""
echo "🔗 Navigate to: https://github.com/YOUR_USERNAME/k8s-game-2048/settings/environments"
