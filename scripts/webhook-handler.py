#!/usr/bin/env python3
"""
Webhook deployment handler for k8s-game-2048
Receives webhook requests from GitHub Actions and deploys to k3s cluster
"""

import hashlib
import hmac
import json
import logging
import os
import subprocess
import time
from datetime import datetime
from flask import Flask, request, jsonify

# Configuration
app = Flask(__name__)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

WEBHOOK_SECRET = os.environ.get('WEBHOOK_SECRET', 'change-me-in-production')
MANIFESTS_PATH = os.environ.get('MANIFESTS_PATH', '/app/manifests')

def verify_signature(payload, signature):
    """Verify HMAC signature from GitHub webhook"""
    if not signature:
        return False
    
    expected = hmac.new(
        WEBHOOK_SECRET.encode('utf-8'),
        payload,
        hashlib.sha256
    ).hexdigest()
    
    return hmac.compare_digest(f"sha256={expected}", signature)

def run_command(cmd, **kwargs):
    """Run shell command with logging"""
    logger.info(f"Running command: {' '.join(cmd)}")
    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True, **kwargs)
        logger.info(f"Command output: {result.stdout}")
        return result
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {e.stderr}")
        raise

def pull_image(image):
    """Pull Docker image to ensure it's available"""
    logger.info(f"Pulling image: {image}")
    run_command(['docker', 'pull', image])

def apply_manifests(environment):
    """Apply Kubernetes manifests for environment"""
    # Map environment names to manifest directories
    env_mapping = {
        'development': 'dev',
        'staging': 'staging', 
        'production': 'prod'
    }
    
    manifest_env = env_mapping.get(environment, environment)
    manifest_dir = f"{MANIFESTS_PATH}/{manifest_env}"
    logger.info(f"Applying manifests from: {manifest_dir} (environment: {environment})")
    
    if not os.path.exists(manifest_dir):
        raise FileNotFoundError(f"Manifest directory not found: {manifest_dir}")
    
    run_command(['kubectl', 'apply', '-f', manifest_dir])

def update_service_image(service_name, namespace, image):
    """Update Knative service with new image"""
    logger.info(f"Updating service {service_name} in namespace {namespace} with image {image}")
    
    patch = {
        "spec": {
            "template": {
                "spec": {
                    "containers": [{
                        "image": image,
                        "imagePullPolicy": "Always"
                    }]
                }
            }
        }
    }
    
    run_command([
        'kubectl', 'patch', 'ksvc', service_name,
        '-n', namespace,
        '--type', 'merge',
        '-p', json.dumps(patch)
    ])

def wait_for_service_ready(service_name, namespace, timeout=300):
    """Wait for Knative service to be ready"""
    logger.info(f"Waiting for service {service_name} to be ready...")
    
    run_command([
        'kubectl', 'wait', '--for=condition=Ready',
        f'ksvc/{service_name}',
        '-n', namespace,
        f'--timeout={timeout}s'
    ])

def implement_blue_green_deployment(service_name, namespace, traffic_split):
    """Implement blue-green deployment with gradual traffic shifting"""
    if not traffic_split:
        return
    
    logger.info("Starting blue-green deployment...")
    
    # Get the latest revision
    result = run_command([
        'kubectl', 'get', 'ksvc', service_name,
        '-n', namespace,
        '-o', 'jsonpath={.status.latestReadyRevisionName}'
    ])
    latest_revision = result.stdout.strip()
    
    if not latest_revision:
        logger.warning("No latest revision found, skipping traffic split")
        return
    
    # Phase 1: Initial traffic (e.g., 10%)
    initial_percent = traffic_split.get('initial', 10)
    logger.info(f"Phase 1: Routing {initial_percent}% traffic to new revision")
    traffic_patch = {
        "spec": {
            "traffic": [
                {"revisionName": latest_revision, "percent": initial_percent},
                {"latestRevision": False, "percent": 100 - initial_percent}
            ]
        }
    }
    run_command([
        'kubectl', 'patch', 'ksvc', service_name,
        '-n', namespace,
        '--type', 'merge',
        '-p', json.dumps(traffic_patch)
    ])
    time.sleep(60)  # Wait 1 minute
    
    # Phase 2: Intermediate traffic (e.g., 50%)
    intermediate_percent = traffic_split.get('intermediate', 50)
    logger.info(f"Phase 2: Routing {intermediate_percent}% traffic to new revision")
    traffic_patch["spec"]["traffic"] = [
        {"revisionName": latest_revision, "percent": intermediate_percent},
        {"latestRevision": False, "percent": 100 - intermediate_percent}
    ]
    run_command([
        'kubectl', 'patch', 'ksvc', service_name,
        '-n', namespace,
        '--type', 'merge',
        '-p', json.dumps(traffic_patch)
    ])
    time.sleep(60)  # Wait 1 minute
    
    # Phase 3: Full traffic (100%)
    logger.info("Phase 3: Routing 100% traffic to new revision")
    traffic_patch["spec"]["traffic"] = [
        {"latestRevision": True, "percent": 100}
    ]
    run_command([
        'kubectl', 'patch', 'ksvc', service_name,
        '-n', namespace,
        '--type', 'merge',
        '-p', json.dumps(traffic_patch)
    ])

@app.route('/webhook/deploy', methods=['POST'])
def deploy():
    """Main webhook endpoint for deployments"""
    try:
        # Verify signature
        signature = request.headers.get('X-Signature-SHA256')
        payload = request.data
        
        logger.info(f"Received webhook request")
        logger.info(f"Signature header: {signature}")
        logger.info(f"Payload length: {len(payload)} bytes")
        logger.info(f"Payload: {payload.decode('utf-8')[:200]}...")
        
        # Test signature verification with debug
        if signature:
            expected = hmac.new(
                WEBHOOK_SECRET.encode('utf-8'),
                payload,
                hashlib.sha256
            ).hexdigest()
            expected_full = f"sha256={expected}"
            logger.info(f"Expected signature: {expected_full}")
            logger.info(f"Received signature: {signature}")
            logger.info(f"Signatures match: {hmac.compare_digest(expected_full, signature)}")
            
            if not verify_signature(payload, signature):
                logger.warning("Invalid webhook signature")
                return jsonify({"error": "Invalid signature"}), 401
        else:
            logger.warning("No signature header found")
            return jsonify({"error": "No signature provided"}), 401
        
        logger.info(f"Signature verification passed")
        
        # Parse payload
        data = request.json
        if not data:
            return jsonify({"error": "No JSON payload"}), 400
        
        # Extract deployment details
        environment = data.get('environment')
        image = data.get('image')
        namespace = data.get('namespace')
        service_name = data.get('service_name')
        deployment_id = data.get('deployment_id')
        deployment_strategy = data.get('deployment_strategy', 'rolling')
        traffic_split = data.get('traffic_split')
        
        # Validate required fields
        required_fields = ['environment', 'image', 'namespace', 'service_name']
        missing_fields = [field for field in required_fields if not data.get(field)]
        if missing_fields:
            return jsonify({"error": f"Missing required fields: {missing_fields}"}), 400
        
        logger.info(f"Starting deployment {deployment_id}")
        logger.info(f"Environment: {environment}")
        logger.info(f"Image: {image}")
        logger.info(f"Namespace: {namespace}")
        logger.info(f"Service: {service_name}")
        logger.info(f"Strategy: {deployment_strategy}")
        
        # Step 1: Skip Docker pull for Knative (Knative handles image pulling)
        logger.info("Skipping Docker pull step (Knative handles image pulling)")
        
        # Step 2: Apply manifests
        apply_manifests(environment)
        
        # Step 3: Update service image
        update_service_image(service_name, namespace, image)
        
        # Step 4: Wait for service to be ready
        wait_for_service_ready(service_name, namespace)
        
        # Step 5: Apply deployment strategy
        if deployment_strategy == 'blue-green' and traffic_split:
            implement_blue_green_deployment(service_name, namespace, traffic_split)
        
        logger.info(f"Deployment {deployment_id} completed successfully")
        
        return jsonify({
            "status": "success",
            "deployment_id": deployment_id,
            "timestamp": datetime.utcnow().isoformat(),
            "environment": environment,
            "image": image,
            "strategy": deployment_strategy
        })
        
    except FileNotFoundError as e:
        logger.error(f"File not found: {e}")
        return jsonify({"error": str(e)}), 404
    
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed: {e}")
        return jsonify({"error": f"Command failed: {e.stderr}"}), 500
    
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    return jsonify({
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "version": "1.0.0"
    })

@app.route('/status', methods=['GET'])
def status():
    """Status endpoint with cluster information"""
    try:
        # Get cluster info
        result = run_command(['kubectl', 'cluster-info'])
        cluster_info = result.stdout
        
        # Get webhook handler pod info
        result = run_command(['kubectl', 'get', 'pods', '-n', 'webhook-system', '--selector=app=webhook-handler'])
        pod_info = result.stdout
        
        return jsonify({
            "status": "operational",
            "timestamp": datetime.utcnow().isoformat(),
            "cluster_info": cluster_info,
            "pod_info": pod_info
        })
    except Exception as e:
        return jsonify({
            "status": "error",
            "timestamp": datetime.utcnow().isoformat(),
            "error": str(e)
        })

if __name__ == '__main__':
    # Verify environment
    logger.info("Starting webhook deployment handler...")
    logger.info(f"Webhook secret configured: {'Yes' if WEBHOOK_SECRET != 'change-me-in-production' else 'No (using default)'}")
    logger.info(f"Manifests path: {MANIFESTS_PATH}")
    
    # Start the Flask app
    app.run(host='0.0.0.0', port=8080, debug=False)
