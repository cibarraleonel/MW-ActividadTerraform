terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.1"
    }
  }
  required_version = "~> 1.10.0"
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "root_pass" {
  default = "mikroways"
}

variable "hostnames" {
  description = "Lista de hostnames para las VMs"
  type        = list(string)
  default     = ["vm1-tofu", "vm2-tofu", "vm3-tofu"]
}

variable "ubuntu_cloudimg" {
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

# Descargar la imagen base una sola vez
resource "libvirt_volume" "ubuntu2404_template" {
  name   = "ubuntu-2404-template.qcow2"
  pool   = "default"
  source = var.ubuntu_cloudimg
  format = "qcow2"
}

# Cloud-init user-data template
locals {
  cloudinit_tpl = <<EOF
#cloud-config
hostname: $${hostname}
create_hostname_file: true
ssh_authorized_keys:
  - $${ssh}
ssh_pwauth: true
chpasswd:
  list: |
    root:$${root_pass}
  expire: false
EOF
}

# Disco (linked clone) para cada VM
resource "libvirt_volume" "vm_disk" {
  for_each        = toset(var.hostnames)
  name            = "${each.key}.qcow2"
  pool            = "default"
  base_volume_id  = libvirt_volume.ubuntu2404_template.id
  format          = "qcow2"
}

# Cloud-init ISO por cada VM
resource "libvirt_cloudinit_disk" "cloudinit" {
  for_each = toset(var.hostnames)
  name     = "cloudinit-${each.key}.iso"
  user_data = templatestring(local.cloudinit_tpl, {
    hostname   = each.key,
    root_pass  = var.root_pass,
    ssh        = file("~/.ssh/id_ed25519.pub")
  })
}

# Crear múltiples dominios (VMs)
resource "libvirt_domain" "vm" {
  for_each   = toset(var.hostnames)
  name       = each.key
  memory     = "2048"
  vcpu       = 2
  autostart  = false

  disk {
    volume_id = libvirt_volume.vm_disk[each.key].id
  }

  cloudinit = libvirt_cloudinit_disk.cloudinit[each.key].id

  network_interface {
    network_name     = "default"
    wait_for_lease   = true
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
}

output "nodes" {
  value = {
    for name, vm in libvirt_domain.vm :
    name => vm.network_interface[0].addresses[0]
  }
}
