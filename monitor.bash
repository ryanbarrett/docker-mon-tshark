#!/bin/bash

# Production Docker container network monitoring script
# Usage: ./monitor.bash <image1> [image2] [image3] ...
# Examples:
#   ./monitor.bash nginx:latest
#   ./monitor.bash nginx:latest redis:alpine postgres:13

set -e

# Configuration
OUTBOUND_DIR="outbound"
LOG_FILE="$OUTBOUND_DIR/monitor.log"
PID_FILE="$OUTBOUND_DIR/monitor.pid"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    mkdir -p "$OUTBOUND_DIR" 2>/dev/null
    echo -e "${BLUE}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    mkdir -p "$OUTBOUND_DIR" 2>/dev/null
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

log_warning() {
    mkdir -p "$OUTBOUND_DIR" 2>/dev/null
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    mkdir -p "$OUTBOUND_DIR" 2>/dev/null
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

show_usage() {
    echo "Docker Container Network Monitor - Production Script"
    echo ""
    echo "Usage: $0 [docker_args] <image>"
    echo ""
    echo "Examples:"
    echo "  $0 nginx:latest                           # Monitor single container"
    echo "  $0 --name nginx_container -p 80:80 nginx:latest  # With docker run args"
    echo "  $0 -e C2_SERVER=evil.com fakin-beacon     # With environment variables"
    echo ""
    echo "All arguments are passed directly to 'docker run -d'. The image name"
    echo "should be the last argument that doesn't start with a dash (-)."
    echo ""
    echo "Output:"
    echo "  - PCAP files: $OUTBOUND_DIR/<container>_<image>_<timestamp>.pcap"
    echo "  - JSON files: $OUTBOUND_DIR/<container>_<image>_<timestamp>.json"
    echo "  - Log file:   $LOG_FILE"
    exit 1
}

setup_environment() {
    log_info "Setting up monitoring environment..."
    
    # Create output directory with proper permissions for the user who started the script
    mkdir -p "$OUTBOUND_DIR"
    
    # If running as root, make the directory accessible to the current user
    if [ "$EUID" -eq 0 ]; then
        # Get the real user if running via sudo
        REAL_USER="${SUDO_USER:-root}"
        REAL_GROUP=$(id -gn "$REAL_USER" 2>/dev/null || echo "root")
        
        # Set ownership to the real user
        chown "$REAL_USER:$REAL_GROUP" "$OUTBOUND_DIR"
        chmod 755 "$OUTBOUND_DIR"
    else
        chmod 755 "$OUTBOUND_DIR"
    fi
    
    # Initialize log
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Docker Monitor Started" > "$LOG_FILE"
    
    # Store PID for cleanup
    echo $$ > "$PID_FILE"
}

check_environment() {
    log_info "Checking environment readiness..."
    
    # Check if running as root or with sudo (needed for network monitoring)
    if [ "$EUID" -ne 0 ] && ! groups | grep -q docker; then
        log_error "This script requires root privileges or docker group membership for network monitoring"
        log_info "Run with: sudo $0 $*"
        exit 1
    fi
    
    # Check Docker daemon
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker daemon is not running or accessible"
        log_info "Please ensure Docker is installed and running"
        exit 1
    fi
    
    # Check Tailscale (optional but expected)
    if command -v tailscale >/dev/null 2>&1; then
        if tailscale status >/dev/null 2>&1; then
            log_success "Tailscale is connected"
        else
            log_warning "Tailscale is installed but not connected"
        fi
    else
        log_warning "Tailscale not found (optional)"
    fi
    
    # Check/Install tshark
    check_install_tshark
}

check_install_tshark() {
    if command -v tshark >/dev/null 2>&1; then
        log_success "tshark is available"
        return 0
    fi
    
    log_warning "tshark not found, attempting to install..."
    
    # Detect package manager and install
    if command -v apt-get >/dev/null 2>&1; then
        log_info "Installing tshark via apt-get..."
        export DEBIAN_FRONTEND=noninteractive
        apt-get update >/dev/null 2>&1
        apt-get install -y tshark >/dev/null 2>&1
        
        # Configure tshark for non-root usage
        echo "wireshark-common wireshark-common/install-setuid boolean true" | debconf-set-selections
        dpkg-reconfigure -f noninteractive wireshark-common >/dev/null 2>&1
        
    elif command -v yum >/dev/null 2>&1; then
        log_info "Installing tshark via yum..."
        yum install -y wireshark >/dev/null 2>&1
        
    elif command -v dnf >/dev/null 2>&1; then
        log_info "Installing tshark via dnf..."
        dnf install -y wireshark >/dev/null 2>&1
        
    else
        log_error "Could not find package manager to install tshark"
        log_info "Please install tshark manually: apt-get install tshark"
        exit 1
    fi
    
    # Verify installation
    if command -v tshark >/dev/null 2>&1; then
        log_success "tshark installed successfully"
    else
        log_error "Failed to install tshark"
        exit 1
    fi
}

normalize_image_name() {
    local image="$1"
    # Convert nginx:latest -> nginx_latest, postgres:13 -> postgres_13
    echo "$image" | sed 's/:/_/g' | sed 's/[^a-zA-Z0-9_]/_/g'
}

get_container_name() {
    local image="$1"
    local normalized=$(normalize_image_name "$image")
    echo "monitor_${normalized}"
}

deploy_container() {
    local docker_args=("$@")
    local image="${docker_args[-1]}"  # Last argument is the image
    local container_name=$(get_container_name "$image")
    
    # Check if --name is already specified in args
    local has_name=false
    for arg in "${docker_args[@]:0:${#docker_args[@]}-1}"; do
        if [ "$arg" = "--name" ]; then
            has_name=true
            break
        fi
    done
    
    log_info "Deploying container from image: $image"
    if [ "$has_name" = "false" ]; then
        log_info "Using generated container name: $container_name"
        
        # Remove existing container if it exists
        if docker ps -a --format "table {{.Names}}" | grep -q "^${container_name}$"; then
            log_info "Removing existing container: $container_name"
            docker rm -f "$container_name" >/dev/null 2>&1
        fi
        
        # Deploy new container with generated name
        if docker run -d --name "$container_name" "${docker_args[@]}" >/dev/null 2>&1; then
            log_success "Container deployed: $container_name"
            echo "$container_name"
            return 0
        else
            log_error "Failed to deploy container: $container_name"
            return 1
        fi
    else
        log_info "Using custom container name from arguments"
        
        # Extract custom name from arguments
        local custom_name=""
        local found_name=false
        for ((i=0; i<${#docker_args[@]}-1; i++)); do
            if [ "${docker_args[$i]}" = "--name" ] && [ $((i+1)) -lt ${#docker_args[@]} ]; then
                custom_name="${docker_args[$((i+1))]}"
                found_name=true
                break
            fi
        done
        
        # Remove existing container if it exists
        if [ "$found_name" = "true" ] && docker ps -a --format "table {{.Names}}" | grep -q "^${custom_name}$"; then
            log_info "Removing existing container: $custom_name"
            docker rm -f "$custom_name" >/dev/null 2>&1
        fi
        
        # Deploy container with user-specified name
        if docker run -d "${docker_args[@]}" >/dev/null 2>&1; then
            if [ "$found_name" = "true" ]; then
                log_success "Container deployed: $custom_name"
                echo "$custom_name"
            else
                # Extract the actual container name from docker ps
                local actual_name=$(docker ps --format "table {{.Names}}" | grep -v "NAMES" | head -1)
                log_success "Container deployed: $actual_name"
                echo "$actual_name"
            fi
            return 0
        else
            log_error "Failed to deploy container with custom arguments"
            return 1
        fi
    fi
}

get_container_veth() {
    local container_name="$1"
    
    # Get container PID
    local pid=$(docker inspect -f '{{.State.Pid}}' "$container_name" 2>/dev/null)
    if [ -z "$pid" ] || [ "$pid" = "0" ]; then
        log_error "Could not get PID for container: $container_name"
        return 1
    fi
    
    # Find veth interface
    local veth_iface=$(ls -l /sys/class/net | grep "veth" | while read -r line; do
        local iface=$(echo "$line" | awk '{print $9}')
        local peer_ifindex=$(cat /sys/class/net/"$iface"/ifindex 2>/dev/null)
        local container_ifindex=$(nsenter -t "$pid" -n ip link 2>/dev/null | grep "@if${peer_ifindex}" | wc -l)
        if [ "$container_ifindex" -gt 0 ]; then
            echo "$iface"
            break
        fi
    done)
    
    if [ -n "$veth_iface" ]; then
        echo "$veth_iface"
        return 0
    else
        log_error "Could not find veth interface for container: $container_name"
        return 1
    fi
}

start_monitoring() {
    local container_name="$1"
    local image="$2"
    local normalized_image=$(normalize_image_name "$image")
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    # Generate output filenames
    local pcap_file="$OUTBOUND_DIR/${container_name}_${normalized_image}_${timestamp}.pcap"
    local json_file="$OUTBOUND_DIR/${container_name}_${normalized_image}_${timestamp}.json"
    local tshark_pid_file="$OUTBOUND_DIR/${container_name}.tshark.pid"
    
    log_info "Starting monitoring for container: $container_name"
    
    # Wait for container to be fully up
    sleep 2
    
    # Get container network interface
    local veth_iface=$(get_container_veth "$container_name")
    if [ -z "$veth_iface" ]; then
        log_error "Cannot monitor $container_name - no network interface found"
        return 1
    fi
    
    log_info "Monitoring interface: $veth_iface -> $pcap_file"
    
    # Create the output file in /tmp first, then move it
    local temp_pcap="/tmp/$(basename "$pcap_file")"
    
    # Start tshark in background writing to temp location
    tshark -i "$veth_iface" -w "$temp_pcap" &
    local tshark_pid=$!
    echo $tshark_pid > "$tshark_pid_file"
    
    # Generate container JSON metadata
    docker inspect "$container_name" > "$json_file" 2>/dev/null
    
    log_success "Monitoring started for $container_name (PID: $tshark_pid)"
    
    # Store monitoring info including temp file location
    echo "$container_name:$tshark_pid:$pcap_file:$json_file:$temp_pcap" >> "$OUTBOUND_DIR/active_monitors.txt"
}

cleanup() {
    log_info "Cleaning up monitoring processes..."
    
    if [ -f "$OUTBOUND_DIR/active_monitors.txt" ]; then
        while IFS=':' read -r container_name tshark_pid pcap_file json_file temp_pcap; do
            if [ -n "$tshark_pid" ] && kill -0 "$tshark_pid" 2>/dev/null; then
                log_info "Stopping tshark for $container_name (PID: $tshark_pid)"
                kill "$tshark_pid" 2>/dev/null
                
                # Wait a moment for tshark to finish writing
                sleep 2
                
                # Move temp file to final location if it exists
                if [ -f "$temp_pcap" ]; then
                    mv "$temp_pcap" "$pcap_file" 2>/dev/null
                    log_info "Moved capture file: $pcap_file"
                fi
            fi
            
            # Stop and remove container
            if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
                log_info "Stopping container: $container_name"
                docker stop "$container_name" >/dev/null 2>&1
                docker rm "$container_name" >/dev/null 2>&1
            fi
        done < "$OUTBOUND_DIR/active_monitors.txt"
        
        rm -f "$OUTBOUND_DIR/active_monitors.txt"
    fi
    
    rm -f "$PID_FILE"
    log_info "Cleanup completed"
}

main() {
    # Check arguments
    if [ $# -eq 0 ]; then
        show_usage
    fi
    
    # Setup signal handlers for cleanup
    trap cleanup EXIT INT TERM
    
    # Initialize
    setup_environment
    check_environment
    
    log_info "🚀 Docker Monitor - Production Script"
    log_info "Processing arguments: $*"
    echo ""
    
    # Simple approach: pass all arguments to deploy_container
    # It will figure out the image name and handle docker args
    log_info "Deploying container with args: $*"
    
    # Deploy container and capture just the container name
    local container_output
    container_output=$(deploy_container "$@" 2>/dev/null)
    local deploy_result=$?
    
    if [ $deploy_result -eq 0 ] && [ -n "$container_output" ]; then
        # Extract container name (last line of output)
        local container_name=$(echo "$container_output" | tail -1)
        
        # Extract image name (last argument that doesn't start with -)
        local image=""
        for arg in "$@"; do
            if [[ ! "$arg" =~ ^- ]]; then
                image="$arg"
            fi
        done
        
        start_monitoring "$container_name" "$image"
    else
        log_error "Failed to deploy container"
        exit 1
    fi
    
    # Show monitoring status
    log_success "All containers deployed and monitoring started"
    log_info "Output directory: $OUTBOUND_DIR"
    log_info "Log file: $LOG_FILE"
    log_info "Monitoring running in background..."
    
    # Keep script running to monitor containers
    log_info "Press Ctrl+C to stop monitoring and cleanup"
    
    # Wait for signal or container completion
    while true; do
        sleep 10
        
        # Check if any containers died
        if [ -f "$OUTBOUND_DIR/active_monitors.txt" ]; then
            local all_dead=true
            while IFS=':' read -r container_name tshark_pid pcap_file json_file temp_pcap; do
                if docker ps --format "table {{.Names}}" | grep -q "^${container_name}$"; then
                    all_dead=false
                else
                    log_warning "Container $container_name is no longer running"
                fi
            done < "$OUTBOUND_DIR/active_monitors.txt"
            
            # If all containers are dead, exit
            if [ "$all_dead" = "true" ]; then
                log_info "All containers have stopped, exiting..."
                break
            fi
        else
            # No active monitors, exit
            log_info "No active monitors found, exiting..."
            break
        fi
    done
}

# Run main function with all arguments
main "$@"