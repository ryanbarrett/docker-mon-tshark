#!/bin/bash

# Destroy script for docker-mon-tshark - destroys all running Terraform infrastructure
# Usage: ./destroy.sh

set -e

TERRAFORM_BIN="/opt/homebrew/bin/terraform"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_terraform() {
    if [ ! -f "$TERRAFORM_BIN" ]; then
        log_error "Terraform not found at $TERRAFORM_BIN"
        log_info "Please install Terraform or update TERRAFORM_BIN path in this script"
        exit 1
    fi
}

destroy_infrastructure() {
    local provider_dir=$1
    local provider_name=$2
    
    if [ ! -d "$provider_dir" ]; then
        log_warning "$provider_name directory not found: $provider_dir"
        return 0
    fi
    
    log_info "Checking $provider_name infrastructure..."
    cd "$provider_dir"
    
    # Check if there's any infrastructure deployed
    if ! $TERRAFORM_BIN show >/dev/null 2>&1; then
        log_info "No $provider_name infrastructure found"
        cd ..
        return 0
    fi
    
    log_warning "Destroying $provider_name infrastructure..."
    if $TERRAFORM_BIN destroy -auto-approve; then
        log_success "$provider_name infrastructure destroyed!"
    else
        log_error "Failed to destroy $provider_name infrastructure"
    fi
    
    cd ..
}

main() {
    log_info ">ù Docker Mon Tshark - Destroy All Infrastructure"
    echo ""
    
    # Check terraform availability
    check_terraform
    
    # Save current directory
    original_dir=$(pwd)
    trap "cd '$original_dir'" EXIT
    
    # Destroy DigitalOcean infrastructure
    destroy_infrastructure "digitalocean-terraform" "DigitalOcean"
    
    # Destroy Linode infrastructure
    destroy_infrastructure "linode-terraform" "Linode"
    
    # Return to original directory
    cd "$original_dir"
    
    echo ""
    log_success "<‰ All infrastructure destroyed!"
    log_info "All VPS instances and associated resources have been removed"
}

# Run main function
main "$@"