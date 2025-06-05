#!/bin/bash

# Deploy script for docker-mon-tshark VPS infrastructure
# Usage: ./deploy.sh <provider> [action]
# Providers: linode|l, digitalocean|do
# Actions: deploy (default), destroy, plan, status

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

show_usage() {
    echo "Usage: $0 <provider> [action]"
    echo ""
    echo "Providers:"
    echo "  linode, l          Deploy on Linode"
    echo "  digitalocean, do   Deploy on DigitalOcean"
    echo ""
    echo "Actions:"
    echo "  deploy             Deploy infrastructure (default)"
    echo "  destroy            Destroy infrastructure"
    echo "  plan               Show deployment plan"
    echo "  status             Show current status"
    echo ""
    echo "Examples:"
    echo "  $0 linode deploy"
    echo "  $0 do destroy"
    echo "  $0 l plan"
    exit 1
}

check_terraform() {
    if [ ! -f "$TERRAFORM_BIN" ]; then
        log_error "Terraform not found at $TERRAFORM_BIN"
        log_info "Please install Terraform or update TERRAFORM_BIN path in this script"
        exit 1
    fi
}

get_provider_dir() {
    case "$1" in
        linode|l)
            echo "linode-terraform"
            ;;
        digitalocean|do)
            echo "digitalocean-terraform"
            ;;
        *)
            log_error "Unknown provider: $1"
            show_usage
            ;;
    esac
}

get_provider_name() {
    case "$1" in
        linode|l)
            echo "Linode"
            ;;
        digitalocean|do)
            echo "DigitalOcean"
            ;;
        *)
            echo "Unknown"
            ;;
    esac
}

check_terraform_vars() {
    local provider_dir=$1
    local tfvars_file="$provider_dir/terraform.tfvars"
    
    if [ ! -f "$tfvars_file" ]; then
        log_error "terraform.tfvars not found in $provider_dir/"
        log_info "Please create $tfvars_file with required variables"
        log_info "See $provider_dir/terraform.tfvars.example for reference"
        exit 1
    fi
}

run_terraform_action() {
    local provider_dir=$1
    local action=$2
    local provider_name=$3
    
    log_info "Switching to $provider_dir directory"
    cd "$provider_dir"
    
    case "$action" in
        deploy)
            log_info "Initializing Terraform for $provider_name..."
            $TERRAFORM_BIN init
            
            log_info "Validating Terraform configuration..."
            $TERRAFORM_BIN validate
            
            log_info "Planning $provider_name deployment..."
            $TERRAFORM_BIN plan
            
            log_warning "Deploying $provider_name infrastructure..."
            $TERRAFORM_BIN apply -auto-approve
            
            log_success "$provider_name VPS deployed successfully!"
            ;;
        destroy)
            log_warning "Destroying $provider_name infrastructure..."
            $TERRAFORM_BIN destroy -auto-approve
            
            log_success "$provider_name infrastructure destroyed!"
            ;;
        plan)
            log_info "Initializing Terraform for $provider_name..."
            $TERRAFORM_BIN init -upgrade
            
            log_info "Planning $provider_name deployment..."
            $TERRAFORM_BIN plan
            ;;
        status)
            log_info "Current $provider_name infrastructure status:"
            if $TERRAFORM_BIN show >/dev/null 2>&1; then
                $TERRAFORM_BIN show
            else
                log_info "No infrastructure currently deployed"
            fi
            ;;
        *)
            log_error "Unknown action: $action"
            show_usage
            ;;
    esac
}

main() {
    # Check arguments
    if [ $# -lt 1 ]; then
        log_error "Missing provider argument"
        show_usage
    fi
    
    local provider=$1
    local action=${2:-deploy}
    
    # Validate inputs
    check_terraform
    
    local provider_dir=$(get_provider_dir "$provider")
    local provider_name=$(get_provider_name "$provider")
    
    # Check if we're in the right directory
    if [ ! -d "$provider_dir" ]; then
        log_error "Provider directory not found: $provider_dir"
        log_info "Please run this script from the project root directory"
        exit 1
    fi
    
    check_terraform_vars "$provider_dir"
    
    log_info "=� Docker Mon Tshark Deployment Script"
    log_info "Provider: $provider_name"
    log_info "Action: $action"
    echo ""
    
    # Save current directory and ensure we return to it
    original_dir=$(pwd)
    trap "cd '$original_dir'" EXIT
    
    # Run the terraform action
    run_terraform_action "$provider_dir" "$action" "$provider_name"
    
    # Return to original directory
    cd "$original_dir"
    
}

# Run main function with all arguments
main "$@"