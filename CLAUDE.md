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

**🎯 Next Phase:** Docker container deployment and network monitoring testing

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
monitor.bash is the production script for monitoring Docker container network traffic using tshark. It is a more advanced version of poc.bash and is recommended for production use. It should be able to detect when a container is started and stopped, and automatically start and stop tshark when the container is started and stopped.

```bash
./monitor.bash <container_name_or_id>
```
It should output the pcap file to the outbound directory. include the container name, image version, and timestamp in the filename. Include a json file containing the inspect output of the container in the same directory. The json file should be named the same as the pcap file, but with a .json extension.
It should have the ability to accept any number of image names as arguments. It should deploy a container, and monitor with tshark, for each image name provided.


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

- [ ] Deploy a test Docker container on chosen VPS via `monitor.bash`
- [ ] Test and validate the `monitor.bash` network monitoring script
- [ ] Verify tshark can capture container network traffic
- [ ] deploy a list of docker containers on the chosen VPS via `monitor.bash`

## Phase 3 Goals

- [ ] deploy kasm
- [ ] deploy the wireshark workspace on kasm with access to the outbound directory

## Phase 4 Goals

- [ ] cleanup any unnecessary files and directories

