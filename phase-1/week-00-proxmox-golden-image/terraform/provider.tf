terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.66.1"
    }
  }
}

provider "proxmox" {
  endpoint = "REDACTED"
  username = "root@pam"
  password = "REDACTED"
  insecure = true
}

