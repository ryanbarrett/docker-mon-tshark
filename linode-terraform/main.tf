# Cloud-init configuration
locals {
  cloud_init_config = templatefile("${path.module}/cloud-init.yaml", {
    tailscale_auth_key = var.tailscale_auth_key
    ssh_public_key     = var.ssh_public_key
  })
}

# Linode Instance
resource "linode_instance" "main" {
  label           = var.instance_label
  image           = var.image
  region          = var.region
  type            = var.instance_type
  authorized_keys = [chomp(var.ssh_public_key)]
  
  metadata {
    user_data = base64encode(local.cloud_init_config)
  }

  # Enable backups for production
  backups_enabled = var.environment == "prod" ? true : false
  
  # Enable private IP
  private_ip = true

  tags = [
    for key, value in var.tags : "${key}:${value}"
  ]
}

# Cloud Firewall
resource "linode_firewall" "main" {
  label = "${var.instance_label}-firewall"

  # Inbound rules - deny all by default
  inbound_policy = "DROP"
  
  # Allow SSH from specified IPs
  dynamic "inbound" {
    for_each = var.allowed_ssh_ips
    content {
      label    = "allow-ssh-${formatdate("YYYYMMDD", timestamp())}"
      action   = "ACCEPT"
      protocol = "TCP"
      ports    = "22"
      ipv4     = [inbound.value]
    }
  }

  # Allow HTTP/HTTPS if needed (uncomment for web servers)
  # inbound {
  #   label    = "allow-http"
  #   action   = "ACCEPT"
  #   protocol = "TCP"
  #   ports    = "80"
  #   ipv4     = ["0.0.0.0/0"]
  #   ipv6     = ["::/0"]
  # }

  # inbound {
  #   label    = "allow-https"
  #   action   = "ACCEPT"
  #   protocol = "TCP"
  #   ports    = "443"
  #   ipv4     = ["0.0.0.0/0"]
  #   ipv6     = ["::/0"]
  # }

  # Outbound rules - allow all
  outbound_policy = "ACCEPT"

  # Associate with instance
  linodes = [linode_instance.main.id]

  tags = [
    for key, value in var.tags : "${key}:${value}"
  ]
}