output "droplet_id" {
  description = "DigitalOcean droplet ID"
  value       = digitalocean_droplet.main.id
}

output "droplet_name" {
  description = "DigitalOcean droplet name"
  value       = digitalocean_droplet.main.name
}

output "public_ipv4" {
  description = "Public IPv4 address"
  value       = digitalocean_droplet.main.ipv4_address
}

output "public_ipv6" {
  description = "Public IPv6 address"
  value       = digitalocean_droplet.main.ipv6_address
}

output "private_ipv4" {
  description = "Private IPv4 address"
  value       = digitalocean_droplet.main.ipv4_address_private
}

output "ssh_connection" {
  description = "SSH connection string"
  value       = "ssh deploy@${digitalocean_droplet.main.ipv4_address}"
}

output "firewall_id" {
  description = "Firewall ID"
  value       = digitalocean_firewall.main.id
}

output "vpc_id" {
  description = "VPC ID"
  value       = digitalocean_vpc.main.id
}

output "reserved_ip" {
  description = "Reserved IP address (if created)"
  value       = var.environment == "prod" ? digitalocean_reserved_ip.main[0].ip_address : null
}