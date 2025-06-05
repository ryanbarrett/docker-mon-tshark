# Data source for SSH key (create manually via web console first)
#data "digitalocean_ssh_key" "main" {
#  name = "${var.droplet_name}-key"
#}

# VPC for network isolation (optional but recommended)
resource "digitalocean_vpc" "main" {
  name     = "${var.droplet_name}-vpc"
  region   = var.region
  ip_range = "10.10.0.0/16"
}

# Cloud-init configuration
locals {
  cloud_init_config = templatefile("${path.module}/cloud-init.yaml", {
    tailscale_auth_key = var.tailscale_auth_key
    ssh_public_key     = var.ssh_public_key
  })
}

# DigitalOcean Droplet
resource "digitalocean_droplet" "main" {
  image     = var.image
  name      = var.droplet_name
  region    = var.region
  size      = var.droplet_size
  vpc_uuid  = digitalocean_vpc.main.id
  
  ssh_keys = []
  
  user_data = local.cloud_init_config
  
  # Enable backups for production
  backups           = var.enable_backups || var.environment == "prod"
  ipv6              = true
  monitoring        = true
  droplet_agent     = true
  
  tags = concat(var.tags, [var.environment])
}

# Cloud Firewall
resource "digitalocean_firewall" "main" {
  name = "${var.droplet_name}-firewall"

  droplet_ids = [digitalocean_droplet.main.id]

  # SSH access from specified IPs
  dynamic "inbound_rule" {
    for_each = var.allowed_ssh_ips
    content {
      protocol         = "tcp"
      port_range       = "22"
      source_addresses = [inbound_rule.value]
    }
  }

  # HTTP/HTTPS (uncomment if needed for web servers)
  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "80"
  #   source_addresses = ["0.0.0.0/0", "::/0"]
  # }

  # inbound_rule {
  #   protocol         = "tcp"
  #   port_range       = "443"
  #   source_addresses = ["0.0.0.0/0", "::/0"]
  # }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  tags = var.tags
}

# Reserved IP (optional, for production)
resource "digitalocean_reserved_ip" "main" {
  count  = var.environment == "prod" ? 1 : 0
  region = var.region
}

resource "digitalocean_reserved_ip_assignment" "main" {
  count      = var.environment == "prod" ? 1 : 0
  ip_address = digitalocean_reserved_ip.main[0].ip_address
  droplet_id = digitalocean_droplet.main.id
}