output "instance_id" {
  description = "Linode instance ID"
  value       = linode_instance.main.id
}

output "instance_label" {
  description = "Linode instance label"
  value       = linode_instance.main.label
}

output "public_ip" {
  description = "Public IPv4 address"
  value       = linode_instance.main.ip_address
}

output "private_ip" {
  description = "Private IPv4 address"
  value       = linode_instance.main.private_ip_address
}

output "ssh_connection" {
  description = "SSH connection string"
  value       = "ssh deploy@${linode_instance.main.ip_address}"
}

output "firewall_id" {
  description = "Firewall ID"
  value       = linode_firewall.main.id
}

output "region" {
  description = "Instance region"
  value       = linode_instance.main.region
}

output "instance_type" {
  description = "Instance type"
  value       = linode_instance.main.type
}