# Fakin-Beacon - C2 Simulation Container

A realistic C2 (Command & Control) beacon simulation for testing network monitoring and detection systems.

## Overview

This container simulates malware beacon behavior commonly seen in real-world attacks, making it perfect for:
- Testing network monitoring tools (like our `monitor.bash`)
- Validating security detection systems
- Training security analysts
- Demonstrating network traffic analysis

## Features

- **Realistic Traffic Patterns**: Variable timing with jitter to avoid detection
- **Multiple Endpoints**: Rotates through different C2 paths
- **Random User Agents**: Simulates different browser/OS combinations
- **JSON Payloads**: Sends structured beacon data
- **Configurable**: Environment variables for customization

## Build & Run

```bash
# Build the image on the remote system
scp fakin-beacon/ deploy@<VPS_IP>:~/tmp
ssh deploy@<VPS_IP> "cd ~/tmp && docker build -t fakin-beacon . && rm -rf ~/tmp"

# Run with defaults (beacons to example.com every 15±5 seconds)
ssh deploy@<VPS_IP> "docker run --name fakin-beacon fakin-beacon"

# Run with custom configuration
ssh deploy@<VPS_IP> "docker run -e C2_SERVER=malicious.domain.com -e BASE_INTERVAL=30 fakin-beacon"
```

## Configuration

Environment variables:
- `C2_SERVER`: Target domain (default: example.com)
- `BASE_INTERVAL`: Base beacon interval in seconds (default: 15)
- `MAX_JITTER`: Maximum random jitter in seconds (default: 5)

## Testing with monitor.bash

```bash
# Pull and monitor the beacon container
docker pull fakin-beacon
sudo ./monitor.bash fakin-beacon

# Monitor with timeout
timeout 120 sudo ./monitor.bash fakin-beacon
```

## Traffic Characteristics

The beacon generates:
- HTTPS POST requests to various endpoints
- JSON payloads with beacon metadata
- Realistic HTTP headers and user agents
- Variable timing (15±5 seconds by default)
- Multiple C2 endpoint patterns

## Security Note

⚠️ **For Testing Only**: This container is designed for security testing and education. Use only in controlled environments for legitimate security research and testing.

## Endpoints Simulated

- `/malicious-request` - Generic malware beacon
- `/api/checkin` - API-style check-in
- `/update/config` - Configuration update request
- `/beacon/status` - Status beacon
- `/cmd/execute` - Command execution endpoint