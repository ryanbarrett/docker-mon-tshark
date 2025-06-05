variable "linode_token" {
  type        = string
  description = "Linode API token"
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
  description = "Linode region"
  default     = "us-east"
  validation {
    condition = contains([
      "us-east", "us-central", "us-west", "us-southeast", "us-mia",
      "ca-central", "eu-west", "eu-central", "ap-south", "ap-northeast",
      "ap-southeast", "ap-west"
    ], var.region)
    error_message = "Region must be a valid Linode region."
  }
}

variable "instance_type" {
  type        = string
  description = "Linode instance type"
  #default     = "g6-standard-1"
  default     = "g6-nanode-1" # smallest size available
  validation {
    condition = can(regex("^g6-(nanode|standard|dedicated|highmem)-", var.instance_type))
    error_message = "Instance type must be a valid Linode type."
  }
}

variable "instance_label" {
  type        = string
  description = "Label for the Linode instance"
  default     = "terraform-vps"
  validation {
    condition     = length(var.instance_label) >= 3 && length(var.instance_label) <= 32
    error_message = "Instance label must be between 3 and 32 characters."
  }
}

variable "image" {
  type        = string
  description = "Operating system image"
  default     = "linode/ubuntu24.04"
  validation {
    condition = contains([
      "linode/ubuntu24.04", "linode/ubuntu22.04", 
      "linode/debian12", "linode/debian11"
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

variable "tags" {
  type        = map(string)
  description = "Tags to apply to resources"
  default = {
    "managed-by" = "terraform"
  }
}