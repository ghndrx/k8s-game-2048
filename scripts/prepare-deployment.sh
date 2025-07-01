#!/bin/bash
set -e

# Environment-aware deployment script
echo "🚀 Environment-aware deployment script..."

# Load environment variables
if [ -f ".env" ]; then
  echo "📋 Loading configuration from .env file..."
  export $(grep -v '^#' .env | xargs)
else
  echo "❌ No .env file found! Please create one from .env.example"
  exit 1
fi

# Validate required environment variables
required_vars=(
  "BASE_DOMAIN"
  "WEBHOOK_DOMAIN" 
  "KNATIVE_DOMAIN"
  "GITHUB_REPOSITORY"
  "CONTAINER_REGISTRY"
)

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "❌ Required environment variable $var is not set!"
    exit 1
  fi
done

echo "✅ Environment validation passed"
echo "   Base Domain: $BASE_DOMAIN"
echo "   Webhook Domain: $WEBHOOK_DOMAIN"
echo "   GitHub Repository: $GITHUB_REPOSITORY"

# Function to substitute environment variables in manifests
substitute_env_vars() {
  local source_dir="$1"
  local target_dir="$2"
  
  echo "📝 Substituting environment variables: $source_dir -> $target_dir"
  
  # Create target directory
  mkdir -p "$target_dir"
  
  # Process all YAML files
  for file in "$source_dir"/*.yml "$source_dir"/*.yaml; do
    if [ -f "$file" ]; then
      local basename=$(basename "$file")
      local target_file="$target_dir/$basename"
      
      # Substitute environment variables
      envsubst < "$file" > "$target_file"
      echo "   ✅ $basename"
    fi
  done
}

# Create deployment-ready manifests from templates
if [ -d "manifests/templates" ]; then
  echo "🔄 Creating deployment manifests from templates..."
  
  substitute_env_vars "manifests/templates/dev" "manifests/dev"
  substitute_env_vars "manifests/templates/staging" "manifests/staging"  
  substitute_env_vars "manifests/templates/prod" "manifests/prod"
  substitute_env_vars "manifests/templates" "manifests"
  
  echo "✅ Deployment manifests ready"
else
  echo "⚠️ No templates directory found, using existing manifests"
fi

echo ""
echo "🎯 Ready for deployment with your environment configuration!"
echo "   Run: kubectl apply -f manifests/dev/"
echo "   Or use: ./scripts/setup-webhook-deployment.sh"
