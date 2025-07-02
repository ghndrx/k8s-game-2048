#!/bin/bash

# Smoke test script for 2048 game deployment
# Tests all environments and validates the complete flow

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
ENVIRONMENTS=("dev" "staging" "prod")
DOMAINS=("${DEV_DOMAIN}" "${STAGING_DOMAIN}" "${PROD_DOMAIN}")
CANONICAL_DOMAINS=("${DEV_CANONICAL_DOMAIN}" "${STAGING_CANONICAL_DOMAIN}" "${PROD_CANONICAL_DOMAIN}")
TIMEOUT=30

echo -e "${BLUE}🧪 Starting 2048 Game Smoke Tests${NC}"
echo "=================================="

# Function to test HTTP response
test_http_response() {
    local url=$1
    local expected_status=$2
    local test_name=$3
    
    echo -n "  Testing $test_name... "
    
    response=$(curl -s -w "%{http_code}" -o /tmp/response.html --max-time $TIMEOUT "$url" 2>/dev/null || echo "000")
    
    if [ "$response" = "$expected_status" ]; then
        echo -e "${GREEN}✅ PASS${NC} (HTTP $response)"
        return 0
    else
        echo -e "${RED}❌ FAIL${NC} (HTTP $response, expected $expected_status)"
        return 1
    fi
}

# Function to test SSL certificate
test_ssl_cert() {
    local domain=$1
    echo -n "  Testing SSL certificate for $domain... "
    
    if echo | openssl s_client -servername "$domain" -connect "$domain:443" -verify_return_error &>/dev/null; then
        echo -e "${GREEN}✅ VALID${NC}"
        return 0
    else
        echo -e "${RED}❌ INVALID${NC}"
        return 1
    fi
}

# Function to test content
test_content() {
    local url=$1
    local expected_text=$2
    local test_name=$3
    
    echo -n "  Testing $test_name content... "
    
    if curl -s --max-time $TIMEOUT "$url" | grep -q "$expected_text"; then
        echo -e "${GREEN}✅ FOUND${NC}"
        return 0
    else
        echo -e "${RED}❌ NOT FOUND${NC}"
        return 1
    fi
}

# Function to test Kubernetes resources
test_k8s_resources() {
    local env=$1
    echo -e "${YELLOW}📋 Testing Kubernetes Resources for $env${NC}"
    
    # Test namespace
    echo -n "  Checking namespace game-2048-$env... "
    if kubectl get namespace "game-2048-$env" &>/dev/null; then
        echo -e "${GREEN}✅ EXISTS${NC}"
    else
        echo -e "${RED}❌ MISSING${NC}"
        return 1
    fi
    
    # Test Knative service
    echo -n "  Checking Knative service... "
    if kubectl get ksvc "game-2048-$env" -n "game-2048-$env" &>/dev/null; then
        local status=$(kubectl get ksvc "game-2048-$env" -n "game-2048-$env" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')
        if [ "$status" = "True" ]; then
            echo -e "${GREEN}✅ READY${NC}"
        else
            echo -e "${YELLOW}⏳ NOT READY${NC} (Status: $status)"
        fi
    else
        echo -e "${RED}❌ MISSING${NC}"
        return 1
    fi
    
    # Test GHCR secret
    echo -n "  Checking GHCR secret... "
    if kubectl get secret ghcr-secret -n "game-2048-$env" &>/dev/null; then
        echo -e "${GREEN}✅ EXISTS${NC}"
    else
        echo -e "${RED}❌ MISSING${NC}"
        return 1
    fi
}

# Function to test ingress
test_ingress() {
    echo -e "${YELLOW}🌐 Testing Ingress Configuration${NC}"
    
    # Test nginx ingress controller
    echo -n "  Checking nginx ingress controller... "
    if kubectl get pods -n ingress-nginx | grep -q "ingress-nginx-controller.*Running"; then
        echo -e "${GREEN}✅ RUNNING${NC}"
    else
        echo -e "${RED}❌ NOT RUNNING${NC}"
        return 1
    fi
    
    # Test Istio ingress gateway
    echo -n "  Checking Istio ingress gateway... "
    if kubectl get pods -n istio-system | grep -q "istio-ingressgateway.*Running"; then
        echo -e "${GREEN}✅ RUNNING${NC}"
    else
        echo -e "${RED}❌ NOT RUNNING${NC}"
        return 1
    fi
    
    # Test cert-manager
    echo -n "  Checking cert-manager... "
    if kubectl get pods -n cert-manager | grep -q "cert-manager.*Running"; then
        echo -e "${GREEN}✅ RUNNING${NC}"
    else
        echo -e "${RED}❌ NOT RUNNING${NC}"
        return 1
    fi
}

# Function to test certificates
test_certificates() {
    echo -e "${YELLOW}🔒 Testing SSL Certificates${NC}"
    
    for i in "${!ENVIRONMENTS[@]}"; do
        local env="${ENVIRONMENTS[$i]}"
        local domain="${DOMAINS[$i]}"
        
        echo -n "  Checking certificate for $domain... "
        local cert_status=$(kubectl get certificate "game-2048-$env-nginx-cert" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "Unknown")
        
        if [ "$cert_status" = "True" ]; then
            echo -e "${GREEN}✅ READY${NC}"
            test_ssl_cert "$domain"
        else
            echo -e "${RED}❌ NOT READY${NC} (Status: $cert_status)"
        fi
    done
}

# Main test execution
main() {
    local total_tests=0
    local passed_tests=0
    
    # Test infrastructure
    test_ingress
    test_certificates
    
    # Test each environment
    for i in "${!ENVIRONMENTS[@]}"; do
        local env="${ENVIRONMENTS[$i]}"
        local domain="${DOMAINS[$i]}"
        local canonical_domain="${CANONICAL_DOMAINS[$i]}"
        
        echo ""
        echo -e "${BLUE}🎮 Testing $env Environment${NC}"
        echo "Domain: https://$domain"
        echo "Canonical: https://$canonical_domain"
        echo "----------------------------------------"
        
        # Test Kubernetes resources
        if test_k8s_resources "$env"; then
            ((total_tests++))
            ((passed_tests++))
        else
            ((total_tests++))
        fi
        
        # Test custom domain accessibility
        if test_http_response "https://$domain" "200\|301\|302" "custom domain"; then
            ((total_tests++))
            ((passed_tests++))
        else
            ((total_tests++))
        fi
        
        # Test canonical domain accessibility  
        if test_http_response "https://$canonical_domain" "200" "canonical domain"; then
            ((total_tests++))
            ((passed_tests++))
        else
            ((total_tests++))
        fi
        
        # Test content
        if test_content "https://$canonical_domain" "2048" "game content"; then
            ((total_tests++))
            ((passed_tests++))
        else
            ((total_tests++))
        fi
        
        # Test environment-specific content
        local env_name=""
        case $env in
            "dev") env_name="development" ;;
            "staging") env_name="staging" ;;
            "prod") env_name="Production" ;;
        esac
        
        if test_content "https://$canonical_domain" "$env_name" "environment detection"; then
            ((total_tests++))
            ((passed_tests++))
        else
            ((total_tests++))
        fi
    done
    
    echo ""
    echo "=================================="
    echo -e "${BLUE}📊 Test Summary${NC}"
    echo "Total Tests: $total_tests"
    echo -e "Passed: ${GREEN}$passed_tests${NC}"
    echo -e "Failed: ${RED}$((total_tests - passed_tests))${NC}"
    
    if [ $passed_tests -eq $total_tests ]; then
        echo -e "${GREEN}🎉 All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}❌ Some tests failed${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
