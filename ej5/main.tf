terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = ">= 0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

data "libvirt_node_info" "host" {}

output "node_info_complete" {
  value = {
    architecture         = data.libvirt_node_info.host.cpu_model
    sockets              = data.libvirt_node_info.host.cpu_sockets
    cores_per_socket     = data.libvirt_node_info.host.cpu_cores_per_socket
    threads_per_core     = data.libvirt_node_info.host.cpu_threads_per_core
    total_cores          = data.libvirt_node_info.host.cpu_cores_total
    total_memory_mb      = data.libvirt_node_info.host.memory_total_kb / 1024
  }
}

