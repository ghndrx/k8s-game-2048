#!/bin/bash
set -e

# Script to sanitize repository by replacing hardcoded values with placeholders
echo "🧹 Sanitizing repository - removing hardcoded personal information..."

# Load environment variables to know what to replace
if [ -f ".env" ]; then
  source .env
else
  echo "❌ No .env file found!"
  exit 1
fi

# Function to replace in file if it exists
replace_in_file() {
  local file="$1"
  local search="$2"
  local replace="$3"
  
  if [ -f "$file" ]; then
    sed -i "s|${search}|${replace}|g" "$file"
    echo "✅ Updated $file"
  fi
}

# Replace domain names in all relevant files
echo "📝 Replacing domain names with placeholders..."

# README.md
replace_in_file "README.md" "$DEV_DOMAIN" "2048-dev.example.com"
replace_in_file "README.md" "$STAGING_DOMAIN" "2048-staging.example.com"
replace_in_file "README.md" "$PROD_DOMAIN" "2048.example.com"
replace_in_file "README.md" "$GITHUB_REPOSITORY" "your-username/k8s-game-2048"

# GitHub workflows - replace all hardcoded domains
for workflow in .github/workflows/*.yml; do
  if [ -f "$workflow" ]; then
    replace_in_file "$workflow" "$DEV_CANONICAL_DOMAIN" "game-2048-dev.game-2048-dev.dev.example.com"
    replace_in_file "$workflow" "$STAGING_CANONICAL_DOMAIN" "game-2048-staging.game-2048-staging.staging.example.com"
    replace_in_file "$workflow" "$PROD_CANONICAL_DOMAIN" "game-2048-prod.game-2048-prod.example.com"
    replace_in_file "$workflow" "$DEV_DOMAIN" "2048-dev.example.com"
    replace_in_file "$workflow" "$STAGING_DOMAIN" "2048-staging.example.com"
    replace_in_file "$workflow" "$PROD_DOMAIN" "2048.example.com"
    replace_in_file "$workflow" "$GITHUB_REPOSITORY" "your-username/k8s-game-2048"
  fi
done

# Scripts
for script in scripts/*.sh; do
  if [ -f "$script" ]; then
    replace_in_file "$script" "$DEV_DOMAIN" "2048-dev.example.com"
    replace_in_file "$script" "$STAGING_DOMAIN" "2048-staging.example.com"
    replace_in_file "$script" "$PROD_DOMAIN" "2048.example.com"
    replace_in_file "$script" "$DEV_CANONICAL_DOMAIN" "game-2048-dev.game-2048-dev.dev.example.com"
    replace_in_file "$script" "$STAGING_CANONICAL_DOMAIN" "game-2048-staging.game-2048-staging.staging.example.com"
    replace_in_file "$script" "$PROD_CANONICAL_DOMAIN" "game-2048-prod.game-2048-prod.example.com"
    replace_in_file "$script" "$KNATIVE_DOMAIN" "example.com"
    replace_in_file "$script" "$WEBHOOK_DOMAIN" "webhook.example.com"
    replace_in_file "$script" "$GITHUB_REPOSITORY" "your-username/k8s-game-2048"
  fi
done

# Manifests - create template versions
echo "📂 Creating template manifests..."
mkdir -p manifests/templates

# Copy current manifests to templates and sanitize
cp -r manifests/dev manifests/templates/
cp -r manifests/staging manifests/templates/
cp -r manifests/prod manifests/templates/
cp manifests/*.yaml manifests/templates/ 2>/dev/null || true

# Sanitize template manifests
for file in manifests/templates/**/*.yml manifests/templates/**/*.yaml manifests/templates/*.yaml; do
  if [ -f "$file" ]; then
    replace_in_file "$file" "$DEV_DOMAIN" "2048-dev.example.com"
    replace_in_file "$file" "$STAGING_DOMAIN" "2048-staging.example.com"
    replace_in_file "$file" "$PROD_DOMAIN" "2048.example.com"
    replace_in_file "$file" "$DEV_CANONICAL_DOMAIN" "game-2048-dev.game-2048-dev.dev.example.com"
    replace_in_file "$file" "$STAGING_CANONICAL_DOMAIN" "game-2048-staging.game-2048-staging.staging.example.com"
    replace_in_file "$file" "$PROD_CANONICAL_DOMAIN" "game-2048-prod.game-2048-prod.example.com"
    replace_in_file "$file" "dev.$KNATIVE_DOMAIN" "dev.example.com"
    replace_in_file "$file" "staging.$KNATIVE_DOMAIN" "staging.example.com"
    replace_in_file "$file" "$KNATIVE_DOMAIN" "example.com"
    replace_in_file "$file" "$GITHUB_REPOSITORY" "your-username/k8s-game-2048"
    replace_in_file "$file" "$CERT_EMAIL" "admin@example.com"
  fi
done

# Package.json
replace_in_file "package.json" "$GITHUB_REPOSITORY" "your-username/k8s-game-2048"

# Documentation
replace_in_file "docs/WEBHOOK_DEPLOYMENT.md" "$KNATIVE_DOMAIN" "example.com"

echo ""
echo "✅ Repository sanitization completed!"
echo ""
echo "📋 Summary of changes:"
echo "- Replaced all domain references with example.com"
echo "- Replaced GitHub repository with placeholder"
echo "- Created template manifests in manifests/templates/"
echo "- Personal information is now only in .env file (which is .gitignored)"
echo ""
echo "⚠️  Note: Current manifests still contain your actual domains for deployment"
echo "   Template manifests are sanitized for public repository"
