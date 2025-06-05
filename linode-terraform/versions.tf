terraform {
  required_version = ">= 1.10"
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "~> 2.41.0"
    }
  }
}

provider "linode" {
  token = var.linode_token
}