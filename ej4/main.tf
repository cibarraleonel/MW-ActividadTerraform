variable "format" {
  description = "Formato del inventario: 'ini' o 'yaml'"
  type        = string
  default     = "yaml"
}

locals {
  hosts = {
    "web-01" = {
      ip_address = "192.168.10.2"
      user       = "mikroways"
    }
    "desktop-01" = {
      ip_address = "192.168.1.50"
      user       = "car"
    }
    "web-02" = {
      ip_address = "192.168.10.3"
      user       = "webadm"
    }
    "db-01" = {
      ip_address = "192.168.20.34"
      user       = "dbadm"
    }
    "db-02" = {
      ip_address = "192.168.20.41"
      user       = "dbadmin"
    }
  }
  # Genero ini
  ini_inventory = concat(
    ["[all]"],
    [for name, data in local.hosts :
      "${name} ansible_host=${data.ip_address} ansible_user=${data.user}"
    ]
  )
  # Genero yaml
  yaml_inventory = {
    all = {
      hosts = {
        for name, data in local.hosts :
        name => {
          ansible_host = data.ip_address
          ansible_user = data.user
        }
      }
    }
  }

  ansible_inventory = (
    var.format == "yaml"
    ? yamlencode(local.yaml_inventory)
    : join("\n", local.ini_inventory)
  )
}

output "ansible_inventory" {
  value = local.ansible_inventory
}
