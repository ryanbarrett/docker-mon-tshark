#!/bin/bash

# Retrieve script for docker-mon-tshark - downloads monitoring output from VPS
# Usage: ./retrieve.bash [vps_ip]

set -e

# Configuration
LOCAL_OUTPUT_DIR="~/docker-mon-output"
REMOTE_OUTBOUND_DIR="outbound"
VPS_USER="deploy"

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
    echo "Docker Monitor Output Retrieval Script"
    echo ""
    echo "Usage: $0 [vps_ip]"
    echo ""
    echo "If no VPS IP is provided, will attempt to get it from terraform output"
    echo ""
    echo "Examples:"
    echo "  $0                           # Auto-detect VPS IP from terraform"
    echo "  $0 45.79.190.149            # Use specific IP"
    echo ""
    echo "Output will be downloaded to: $LOCAL_OUTPUT_DIR"
    exit 1
}

get_vps_ip() {
    local vps_ip=""
    
    # Check if IP was provided as argument
    if [ -n "$1" ]; then
        vps_ip="$1"
        echo "$vps_ip"
        return 0
    fi
    
    # Try to get IP from terraform output
    log_info "Attempting to get VPS IP from terraform..."
    
    # Check linode-terraform first
    if [ -d "linode-terraform" ]; then
        cd linode-terraform
        vps_ip=$(/opt/homebrew/bin/terraform output -raw public_ip 2>/dev/null || echo "")
        cd ..
        
        if [ -n "$vps_ip" ] && [ "$vps_ip" != "null" ]; then
            log_success "Found Linode VPS IP: $vps_ip"
            echo "$vps_ip"
            return 0
        fi
    fi
    
    # Check digitalocean-terraform
    if [ -d "digitalocean-terraform" ]; then
        cd digitalocean-terraform
        vps_ip=$(/opt/homebrew/bin/terraform output -raw public_ipv4 2>/dev/null || echo "")
        cd ..
        
        if [ -n "$vps_ip" ] && [ "$vps_ip" != "null" ]; then
            log_success "Found DigitalOcean VPS IP: $vps_ip"
            echo "$vps_ip"
            return 0
        fi
    fi
    
    log_error "Could not determine VPS IP automatically"
    log_info "Please provide VPS IP as argument: $0 <vps_ip>"
    return 1
}

fix_remote_permissions() {
    local vps_ip="$1"
    
    log_info "Fixing permissions on remote VPS..."
    
    # Fix permissions for pcap and json files
    ssh "$VPS_USER@$vps_ip" "
        if [ -d '$REMOTE_OUTBOUND_DIR' ]; then
            sudo chmod 644 $REMOTE_OUTBOUND_DIR/*.pcap $REMOTE_OUTBOUND_DIR/*.json 2>/dev/null || true
            sudo chown $VPS_USER:$VPS_USER $REMOTE_OUTBOUND_DIR/*.pcap $REMOTE_OUTBOUND_DIR/*.json 2>/dev/null || true
            sudo chmod 755 $REMOTE_OUTBOUND_DIR
            sudo chown $VPS_USER:$VPS_USER $REMOTE_OUTBOUND_DIR
            echo 'Permissions fixed'
        else
            echo 'No outbound directory found'
            exit 1
        fi
    "
    
    if [ $? -eq 0 ]; then
        log_success "Remote permissions fixed"
    else
        log_error "Failed to fix remote permissions"
        return 1
    fi
}

download_files() {
    local vps_ip="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local session_dir="$LOCAL_OUTPUT_DIR/session_${timestamp}"
    
    log_info "Creating local output directory: $session_dir"
    mkdir -p "$session_dir"
    
    log_info "Downloading files from VPS..."
    
    # Download all files from outbound directory
    if scp -r "$VPS_USER@$vps_ip:$REMOTE_OUTBOUND_DIR/*" "$session_dir/" 2>/dev/null; then
        log_success "Files downloaded to: $session_dir"
        
        # Show what was downloaded
        log_info "Downloaded files:"
        ls -la "$session_dir/"
        
        # Show file counts and sizes
        local pcap_count=$(find "$session_dir" -name "*.pcap" | wc -l)
        local json_count=$(find "$session_dir" -name "*.json" | wc -l)
        
        log_info "Summary: $pcap_count PCAP files, $json_count JSON files"
        
        # Show PCAP file sizes
        if [ "$pcap_count" -gt 0 ]; then
            log_info "PCAP file sizes:"
            find "$session_dir" -name "*.pcap" -exec ls -lh {} \; | awk '{print "  " $9 ": " $5}'
        fi
        
        echo ""
        log_success "Download completed successfully!"
        log_info "Files available in: $session_dir"
        
    else
        log_error "Failed to download files from VPS"
        log_warning "Make sure the VPS has monitoring output in the outbound directory"
        return 1
    fi
}

cleanup_remote() {
    local vps_ip="$1"
    
    log_warning "Do you want to clean up the remote outbound directory? (y/N)"
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        log_info "Cleaning up remote outbound directory..."
        ssh "$VPS_USER@$vps_ip" "sudo rm -rf $REMOTE_OUTBOUND_DIR"
        log_success "Remote cleanup completed"
    else
        log_info "Remote files left intact"
    fi
}

main() {
    log_info "🔽 Docker Monitor Output Retrieval"
    echo ""
    
    # Expand tilde in LOCAL_OUTPUT_DIR
    LOCAL_OUTPUT_DIR=$(eval echo "$LOCAL_OUTPUT_DIR")
    
    # Get VPS IP
    local vps_ip=$(get_vps_ip "$1")
    if [ $? -ne 0 ]; then
        show_usage
    fi
    
    log_info "Using VPS IP: $vps_ip"
    
    # Test SSH connectivity
    log_info "Testing SSH connectivity to $vps_ip..."
    if ! ssh -o ConnectTimeout=10 "$VPS_USER@$vps_ip" "echo 'SSH connection successful'" >/dev/null 2>&1; then
        log_error "Cannot connect to VPS via SSH"
        log_info "Please ensure:"
        log_info "  - VPS is running and accessible"
        log_info "  - SSH key is properly configured"
        log_info "  - IP address is correct: $vps_ip"
        exit 1
    fi
    log_success "SSH connection successful"
    
    # Fix remote permissions
    fix_remote_permissions "$vps_ip"
    
    # Download files
    download_files "$vps_ip"
    
    # Offer to cleanup remote files
    cleanup_remote "$vps_ip"
    
    echo ""
    log_success "🎉 Retrieval completed!"
}

# Show usage if help requested
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_usage
fi

# Run main function
main "$@"