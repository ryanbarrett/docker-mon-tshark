# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository contains Terraform infrastructure code for deploying secure, Docker-enabled VPS instances on DigitalOcean and Linode cloud providers. The project includes a proof-of-concept script for monitoring Docker container network traffic using tshark.

## Current Project Status

**✅ Phase 1 Complete:** Infrastructure setup and provider selection
- Multi-cloud VPS deployment (DigitalOcean & Linode)
- Automated Tailscale VPN integration
- Docker CE with security hardening
- Unified deployment management via `tf-manager.sh`
- Quick infrastructure cleanup via `destroy.sh`

**✅ Phase 2 Complete:** Production container monitoring system
- `monitor.bash` production monitoring script with docker args support
- Automatic environment detection and tshark installation
- Container lifecycle management and network traffic capture
- `fakin-beacon` C2 simulation container for testing
- `retrieve.bash` for downloading monitoring results

**🎯 Next Phase:** Scalable analysis and Kasm workspace integration

## Management Scripts

- **`tf-manager.sh`** - Unified Terraform deployment manager for both cloud providers
- **`destroy.sh`** - Quick cleanup script to destroy all running infrastructure
- **`poc.bash`** - Proof-of-concept script for monitoring Docker container network traffic

## Architecture

The project is organized into provider-specific configurations and reusable modules:

- **Provider Configurations**: `digitalocean-terraform/` and `linode-terraform/` contain environment-specific configurations
- **Reusable Modules**: `modules/digitalocean-vps/` and `modules/linode-vps/` provide standardized VPS configurations
- **Network Monitoring**: `poc.bash` demonstrates Docker container network traffic capture using tshark

Both cloud providers deploy identical security-hardened configurations:
- Ubuntu 24.04 LTS base image with automatic security updates
- Docker CE with security-focused daemon configuration
- Tailscale VPN integration for secure remote access
- SSH hardening (key-only auth, fail2ban protection)
- Cloud firewalls with minimal attack surface
- Production environments include automated backups

## Key Commands

### Terraform Manager Script (Recommended)
```bash
# Deploy on Linode
./tf-manager.sh linode deploy
./tf-manager.sh l deploy

# Deploy on DigitalOcean  
./tf-manager.sh digitalocean deploy
./tf-manager.sh do deploy

# Plan deployment
./tf-manager.sh l plan
./tf-manager.sh do plan

# Destroy infrastructure
./tf-manager.sh l destroy
./tf-manager.sh do destroy

# Check status
./tf-manager.sh l status
./tf-manager.sh do status
```

### Quick Destroy All Infrastructure
```bash
# Destroy all running infrastructure across both providers
./destroy.sh
```

### Direct Terraform Operations
```bash
# Initialize Terraform (run in digitalocean-terraform/ or linode-terraform/)
terraform init

# Plan deployment
terraform plan -var-file="terraform.tfvars"

# Deploy infrastructure
terraform apply -var-file="terraform.tfvars"

# Destroy infrastructure
terraform destroy -var-file="terraform.tfvars"

# Format Terraform files
terraform fmt -recursive

# Validate configuration
terraform validate
```

### Docker Network Monitoring

#### poc.bash
```bash
# proof of concept script for monitoring Docker container network traffic using tshark. Do not modify this file. However, you can use it as a base to start from. for the production script, see `monitor.bash`
./poc.bash <container_name_or_id>
```

#### monitor.bash
monitor.bash runs a Docker container and monitors its network traffic using tshark. It is a more advanced version of poc.bash and is recommended for production use. It automatically detects when containers are started and stopped, and manages tshark monitoring accordingly.

```bash
# Basic container monitoring
sudo ./monitor.bash nginx:latest

# With docker run arguments (NEW)
sudo ./monitor.bash --name nginx_container -p 80:80 nginx:latest
sudo ./monitor.bash -e C2_SERVER=evil.com fakin-beacon
sudo ./monitor.bash -v /data:/app/data --restart unless-stopped redis:alpine

# With timeout (recommended for testing)
timeout 60 sudo ./monitor.bash fakin-beacon
timeout 90 sudo ./monitor.bash --name test_nginx -p 8080:80 nginx:latest
```

**Features:**
- Automatic environment detection (Docker, Tailscale, tshark)
- Auto-install tshark if missing
- **NEW:** Support for all docker run arguments (ports, environment, volumes, etc.)
- Deploy containers from image names with predictable naming
- Background network monitoring with tshark
- Structured output with timestamps
- Automatic container lifecycle management

**Usage Pattern:**
All arguments are passed directly to `docker run -d`. The image name should be the last argument that doesn't start with a dash (-).

**Output:**
- PCAP files: `outbound/<container>_<image>_<timestamp>.pcap`
- JSON files: `outbound/<container>_<image>_<timestamp>.json` (container inspect data)
- Log file: `outbound/monitor.log`

#### retrieve.bash
retrieve.bash downloads monitoring output from the VPS to local machine, fixing permissions and organizing files by session.

```bash
# Auto-detect VPS IP from terraform
./retrieve.bash

# Use specific VPS IP
./retrieve.bash 45.79.190.149
```

**Features:**
- Auto-detects VPS IP from terraform output
- Fixes remote file permissions automatically
- Downloads to `~/docker-mon-output/session_TIMESTAMP/`
- Shows file summary and sizes
- Optional remote cleanup after download


## Required Variables

Both provider configurations require these sensitive variables in `terraform.tfvars`:
- `do_token` or `linode_token`: Cloud provider API token
- `tailscale_auth_key`: Tailscale authentication key for VPN setup
- `ssh_public_key`: SSH public key for server access

## Security Considerations

- SSH keys must be pre-created in DigitalOcean console before deployment
- Default SSH access allows all IPs (0.0.0.0/0) - restrict `allowed_ssh_ips` for production
- Production environments automatically enable backups and reserved IPs
- All instances include fail2ban, UFW firewall, and SSH hardening
- Docker daemon configured with security best practices (no-new-privileges, userland-proxy disabled)

## Infrastructure Differences

**DigitalOcean**:
- Uses Droplets with VPC networking
- Reserved IP support for production
- Cloud firewall with granular rules

**Linode**:
- Uses Linodes with private IP enabled
- Tag-based resource organization
- Cloud firewall with inbound/outbound policies


## Phase 1 Goals

- [x] Deploy a VPS on DigitalOcean with Tailscale and Docker installed
- [x] Deploy a VPS on Linode with Tailscale and Docker installed
- [x] Verify that the VPSes are accessible from the tailscale network over ssh
- [x] Set up a way to choose the VPS to use for the rest of the project (deploy.sh script)

## Phase 2 Goals

- [x] Deploy a test Docker container on chosen VPS via `monitor.bash`
- [x] Test and validate the `monitor.bash` network monitoring script
- [x] Verify tshark can capture container network traffic
- [x] Fix container lifecycle issues in monitoring script
- [x] Add support for docker run arguments (ports, environment, volumes, etc.)
- [x] Create fakin-beacon C2 simulation container for testing
- [x] Test realistic network traffic capture with fakin-beacon

## Phase 3 Goals

- [ ] deploy kasm
- [ ] deploy the wireshark workspace on kasm with access to the outbound directory

## Phase 4 Goals

- [ ] cleanup any unnecessary files and directories

