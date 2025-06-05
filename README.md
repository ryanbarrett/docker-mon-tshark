# Docker Monitor Tshark

A comprehensive Docker container network monitoring system with multi-cloud infrastructure deployment and realistic C2 simulation for security testing.

## Overview

This project provides a complete solution for monitoring Docker container network traffic using tshark, with automated VPS deployment on DigitalOcean and Linode, and a realistic C2 beacon simulation for testing detection capabilities.

## 🎯 Project Goals

- **Phase 1**: Multi-cloud VPS deployment with Docker and network monitoring tools ✅
- **Phase 2**: Production container monitoring with docker args support ✅
- **Phase 3**: Scalable analysis and Kasm workspace integration 🚧
- **Phase 4**: Advanced analysis tools and cleanup 📋

## 🏗️ Architecture

```
Local Development
├── tf-manager.sh          # Unified deployment management
├── destroy.sh            # Quick infrastructure cleanup
├── monitor.bash          # Production monitoring script
├── retrieve.bash         # Download monitoring results
└── fakin-beacon/         # C2 simulation container

Cloud Infrastructure
├── digitalocean-terraform/  # DigitalOcean VPS deployment
├── linode-terraform/        # Linode VPS deployment
└── modules/                 # Reusable Terraform modules

Monitoring Output
└── ~/docker-mon-output/     # Local analysis directory
    └── session_TIMESTAMP/
        ├── *.pcap          # Network captures
        ├── *.json          # Container metadata
        └── monitor.log     # Operation logs
```

## 🚀 Quick Start

### 1. Deploy Infrastructure

```bash
# Deploy on Linode (recommended)
./tf-manager.sh l deploy

# Or deploy on DigitalOcean
./tf-manager.sh do deploy

# Check deployment status
./tf-manager.sh l status
```

### 2. Monitor Containers

```bash
# SSH to your VPS (IP from terraform output)
ssh deploy@<VPS_IP>

# Basic container monitoring
sudo ./monitor.bash nginx:latest

# With docker run arguments
sudo ./monitor.bash --name nginx_container -p 80:80 nginx:latest
sudo ./monitor.bash -e C2_SERVER=evil.com fakin-beacon

# With timeout (recommended for testing)
timeout 120 sudo ./monitor.bash nginx:latest
timeout 60 sudo ./monitor.bash --name test_nginx -p 8080:80 nginx:latest
```

### 3. Retrieve Results

```bash
# specify VPS IP manually
./retrieve.bash <VPS_IP>
```

### 4. Test with C2 Simulation

```bash
# Build the C2 beacon container
cd fakin-beacon
docker build -t fakin-beacon .

# Monitor the beacon traffic
sudo ../monitor.bash fakin-beacon
```

## 📁 Directory Structure

### Core Scripts
- **`tf-manager.sh`** - Unified infrastructure deployment and management
- **`destroy.sh`** - Emergency cleanup of all cloud resources
- **`monitor.bash`** - Production container monitoring with tshark
- **`retrieve.bash`** - Download and organize monitoring results
- **`poc.bash`** - Original proof-of-concept (reference only)

### Infrastructure
- **`digitalocean-terraform/`** - DigitalOcean deployment configuration
- **`linode-terraform/`** - Linode deployment configuration  
- **`modules/`** - Reusable Terraform VPS modules

### Testing
- **`fakin-beacon/`** - Realistic C2 beacon simulation container

### Documentation
- **`CLAUDE.md`** - Detailed technical documentation and command reference
- **`fakin-beacon/README.md`** - C2 simulation container documentation
- **Provider READMEs** - Cloud-specific deployment guides

## 🔧 Requirements

### Local Machine
- Terraform 1.10+ (`/opt/homebrew/bin/terraform`)
- SSH client with key-based authentication
- Cloud provider accounts (DigitalOcean/Linode)
- Tailscale account (optional but recommended)

### Cloud Credentials
Create `terraform.tfvars` files in provider directories:

```bash
# Required for both providers
tailscale_auth_key = "your-tailscale-auth-key"
ssh_public_key     = "your-ssh-public-key"

# DigitalOcean
do_token = "your-digitalocean-token"

# Linode  
linode_token = "your-linode-token"
```

## 📊 Monitoring Features

### Automatic Environment Setup
- ✅ Docker daemon verification
- ✅ Tailscale connectivity check
- ✅ Auto-install tshark if missing
- ✅ Network interface detection

### Container Management
- ✅ Predictable container naming (`monitor_<image>_<tag>`)
- ✅ **NEW:** Support for all docker run arguments (ports, environment, volumes, etc.)
- ✅ Custom container naming with `--name` argument
- ✅ Background process management and lifecycle control
- ✅ Clean shutdown and cleanup

### Output Organization
- ✅ Structured file naming with timestamps
- ✅ PCAP files for network analysis
- ✅ JSON metadata from container inspection
- ✅ Detailed operation logging

## 🔒 Security Features

### Infrastructure Hardening
- SSH key-only authentication
- Fail2ban intrusion prevention
- UFW/Cloud firewall protection
- Automatic security updates
- Docker daemon security configuration

### Network Isolation
- VPC/private networking
- Tailscale VPN integration
- Minimal attack surface
- Production backup strategies

## 📖 Documentation

- **[CLAUDE.md](CLAUDE.md)** - Complete technical reference
- **[Security Considerations](SECURITY.md)** - Security best practices
- **[Troubleshooting](TROUBLESHOOTING.md)** - Common issues and solutions
- **[C2 Simulation Guide](fakin-beacon/README.md)** - Beacon testing documentation

## 🧪 Testing & Validation

### Built-in Test Container
The `fakin-beacon` container provides realistic C2 traffic for testing:

```bash
# Build and monitor beacon traffic
cd fakin-beacon && docker build -t fakin-beacon .
sudo ../monitor.bash fakin-beacon
```

### Traffic Analysis
Use the captured PCAP files with:
- Wireshark for detailed packet analysis
- tshark command-line analysis
- Custom analysis scripts

## 🎛️ Management Commands

```bash
# Infrastructure Management
./tf-manager.sh l deploy      # Deploy Linode VPS
./tf-manager.sh do destroy    # Destroy DigitalOcean VPS
./destroy.sh                  # Emergency cleanup all providers

# Monitoring
sudo ./monitor.bash nginx:latest                    # Basic monitoring
sudo ./monitor.bash --name web -p 80:80 nginx       # With docker args
sudo ./monitor.bash -e VAR=value redis:alpine       # With environment
./retrieve.bash                                     # Download results locally

# Status Checks
./tf-manager.sh l status      # Check infrastructure status
```

## 🤝 Contributing

This project follows a phased development approach. Current status:

- ✅ **Phase 1 Complete**: Infrastructure and provider selection
- ✅ **Phase 2 Complete**: Production container monitoring with docker args support
- 🚧 **Phase 3 In Progress**: Scalable analysis and Kasm integration

## 🔗 Related Projects

- [Wireshark](https://www.wireshark.org/) - Network protocol analyzer
- [Tailscale](https://tailscale.com/) - Secure networking
- [Terraform](https://terraform.io/) - Infrastructure as code

## ⚠️ Disclaimer

This project is designed for legitimate security research, testing, and education. The C2 simulation components are for controlled testing environments only. Users are responsible for compliance with applicable laws and regulations.