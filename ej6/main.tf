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
variable "hostname" {
  default = "tf-vm"
}
variable "ubuntu_cloudimg" {
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

# se descarga una vez
resource "libvirt_volume" "ubuntu2404_template" {
  name   = "ubuntu-2404-template.qcow2"
  pool   = "default"
  source = var.ubuntu_cloudimg
  format = "qcow2"
}

# Disco usando linked clone
resource "libvirt_volume" "vm_disk" {
  name           = "${var.hostname}.qcow2"
  pool           = "default"
  base_volume_id = libvirt_volume.ubuntu2404_template.id
  format         = "qcow2"
}

locals {
  cloudinit_tpl = <<EOF
#cloud-config
hostname: $${hostname}
create_hostname_file: true
ssh_authorized_keys:
  - $${ssh}
ssh_pwauth: True
chpasswd:
  list: |
    root:$${root_pass}
  expire: False
EOF
}

resource "libvirt_cloudinit_disk" "vm" {
  name = "cloudinit-${var.hostname}.iso"
  user_data = templatestring(local.cloudinit_tpl, {
    hostname  = var.hostname
    root_pass = var.root_pass
    ssh       = file("/home/leonelibarra/.ssh/id_ed25519.pub")
  })
}

# Máquina virtual
resource "libvirt_domain" "vm" {
  name   = var.hostname
  memory = "2048"
  vcpu   = 2
  autostart = false

  disk { volume_id = libvirt_volume.vm_disk.id}

  cloudinit = libvirt_cloudinit_disk.vm.id

  network_interface {
    network_name    = "default"
    wait_for_lease  = true
  }

  console {
    type         = "pty"
    target_type  = "serial"
    target_port  = "0"
  }
}

output "node" {
  value = libvirt_domain.vm.network_interface
}
