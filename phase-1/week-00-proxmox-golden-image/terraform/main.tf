resource "proxmox_virtual_environment_vm" "phase1_vms" {
  count     = 2
  name      = "phase1-vm-${count.index + 1}"
  node_name = "pve"

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = 4096
  }

  clone {
    vm_id = 101
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 32
  }

  network_device {
    bridge = "vmbr0"
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
}
