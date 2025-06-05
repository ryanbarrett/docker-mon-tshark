variable "do_token" {
  type        = string
  description = "DigitalOcean API token"
  sensitive   = true
}

variable "tailscale_auth_key" {
  type        = string
  description = "Tailscale auth key for device registration"
  sensitive   = true
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for server access"
}

variable "region" {
  type        = string
  description = "DigitalOcean region"
  default     = "nyc1"
  validation {
    condition = contains([
      "nyc1", "nyc3", "ams3", "sfo3", "sgp1", "lon1", "fra1", "tor1", "blr1", "syd1"
    ], var.region)
    error_message = "Region must be a valid DigitalOcean region."
  }
}

variable "droplet_size" {
  type        = string
  description = "DigitalOcean droplet size"
  #default     = "s-1vcpu-1gb"
  default     = "s-1vcpu-512mb-10gb" # smallest size available
  validation {
    condition = can(regex("^(s-|c-|m-|so-)", var.droplet_size))
    error_message = "Droplet size must be a valid DigitalOcean size."
  }
}

variable "droplet_name" {
  type        = string
  description = "Name for the droplet"
  default     = "terraform-vps"
  validation {
    condition     = length(var.droplet_name) >= 1 && length(var.droplet_name) <= 64
    error_message = "Droplet name must be between 1 and 64 characters."
  }
}

variable "image" {
  type        = string
  description = "Operating system image"
  default     = "ubuntu-24-04-x64"
  validation {
    condition = contains([
      "ubuntu-24-04-x64", "ubuntu-22-04-x64", "ubuntu-20-04-x64",
      "debian-12-x64", "debian-11-x64"
    ], var.image)
    error_message = "Image must be a supported Ubuntu LTS or Debian version."
  }
}

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "allowed_ssh_ips" {
  type        = list(string)
  description = "List of IP addresses/CIDR blocks allowed SSH access"
  default     = ["0.0.0.0/0"]  # Change this for production
  validation {
    condition = alltrue([
      for cidr in var.allowed_ssh_ips : can(cidrhost(cidr, 0))
    ])
    error_message = "All elements must be valid CIDR blocks."
  }
}

variable "enable_backups" {
  type        = bool
  description = "Enable automated backups"
  default     = false
}

variable "tags" {
  type        = list(string)
  description = "Tags to apply to resources"
  default     = ["terraform", "vps"]
  validation {
    condition     = length(var.tags) <= 5
    error_message = "Maximum of 5 tags allowed per resource."
  }
}