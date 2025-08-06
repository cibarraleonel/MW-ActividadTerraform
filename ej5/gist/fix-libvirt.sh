#!/bin/bash

# ============================================
# SCRIPT AGRESIVO DE LIMPIEZA COMPLETA
# Elimina TODAS las VMs sin excepción
# ============================================

echo "========================================"
echo "LIMPIEZA AGRESIVA - ELIMINANDO TODO"
echo "========================================"

# PASO 1: Eliminar ABSOLUTAMENTE TODAS las VMs existentes
echo "PASO 1: Eliminando TODAS las VMs existentes..."

# Eliminar por nombres específicos problemáticos
for name in "Ubuntu-vm" "ubuntu-vm" "ubuntu-vm-1" "ubuntu-vm-2" "ubuntu-vm-3" "ubuntu-vm-4" "tf-vm"; do
    echo "  Eliminando: $name"
    virsh destroy "$name" 2>/dev/null || true
    virsh undefine "$name" 2>/dev/null || true
done

# Eliminar por UUIDs específicos problemáticos
for uuid in "e1d41d0c-09e9-4598-92dc-71bfbef3dd64" "7fa3b0b3-2e2c-4e77-9506-ce3598ac3f56"; do
    echo "  Eliminando UUID: $uuid"
    virsh destroy "$uuid" 2>/dev/null || true
    virsh undefine "$uuid" 2>/dev/null || true
done

# Eliminar TODAS las VMs que aparezcan en la lista
for vm in $(virsh list --all --name 2>/dev/null); do
    if [ ! -z "$vm" ] && [ "$vm" != " " ]; then
        echo "  Eliminando VM encontrada: $vm"
        virsh destroy "$vm" 2>/dev/null || true
        virsh undefine "$vm" --remove-all-storage 2>/dev/null || true
    fi
done

# PASO 2: Eliminar archivos de configuración XML de forma agresiva
echo "PASO 2: Eliminando TODOS los archivos XML..."
sudo rm -f /etc/libvirt/qemu/*.xml 2>/dev/null || true
sudo rm -f /var/lib/libvirt/qemu/*.xml 2>/dev/null || true
sudo rm -rf /var/lib/libvirt/qemu/domain-* 2>/dev/null || true

# PASO 3: Eliminar TODOS los volúmenes del pool default
echo "PASO 3: Eliminando TODOS los volúmenes..."
for vol in $(virsh vol-list default 2>/dev/null | tail -n +3 | awk '{print $1}'); do
    if [ ! -z "$vol" ]; then
        echo "  Eliminando volumen: $vol"
        virsh vol-delete "$vol" --pool default 2>/dev/null || true
    fi
done

# PASO 4: Eliminar físicamente TODOS los archivos de imágenes
echo "PASO 4: Eliminando archivos físicos..."
sudo rm -f /var/lib/libvirt/images/*.iso 2>/dev/null || true
sudo rm -f /var/lib/libvirt/images/*.qcow2 2>/dev/null || true
sudo rm -f /var/lib/libvirt/images/*.img 2>/dev/null || true

# PASO 5: Limpiar cachés y logs
echo "PASO 5: Limpiando cachés y logs..."
sudo rm -rf /var/lib/libvirt/qemu/save/* 2>/dev/null || true
sudo rm -rf /var/lib/libvirt/qemu/snapshot/* 2>/dev/null || true
sudo rm -rf /var/lib/libvirt/qemu/dump/* 2>/dev/null || true
sudo rm -rf /var/log/libvirt/qemu/*.log 2>/dev/null || true

# PASO 6: Parar COMPLETAMENTE libvirt
echo "PASO 6: Parando completamente libvirt..."
sudo systemctl stop libvirtd
sudo systemctl stop libvirtd.socket
sudo systemctl stop virtlogd
sudo systemctl stop virtlockd
sudo systemctl stop libvirt-guests

# Matar cualquier proceso libvirt que quede
sudo pkill -f libvirtd 2>/dev/null || true
sudo pkill -f qemu-system 2>/dev/null || true

sleep 3

# PASO 7: Limpiar estado completo de Terraform
echo "PASO 7: Limpiando Terraform completamente..."
tofu destroy -auto-approve 2>/dev/null || true
rm -f terraform.tfstate* 2>/dev/null || true
rm -f .terraform.lock.hcl 2>/dev/null || true
rm -rf .terraform/ 2>/dev/null || true

# PASO 8: Configurar permisos correctos
echo "PASO 8: Configurando permisos..."
sudo chown -R libvirt-qemu:libvirt-qemu /var/lib/libvirt/images/
sudo chmod 755 /var/lib/libvirt/images/

# PASO 9: Reinicializar libvirt desde cero
echo "PASO 9: Reinicializando libvirt..."
sudo systemctl start virtlockd
sudo systemctl start virtlogd  
sudo systemctl start libvirtd.socket
sudo systemctl start libvirtd

sleep 5

# PASO 10: Recrear el pool si es necesario
echo "PASO 10: Verificando pool..."
virsh pool-info default >/dev/null 2>&1 || {
    echo "  Recreando pool default..."
    virsh pool-define-as --name default --type dir --target /var/lib/libvirt/images
    virsh pool-start default
    virsh pool-autostart default
}

virsh pool-refresh default

# PASO 11: Inicializar Terraform desde cero
echo "PASO 11: Inicializando Terraform..."
tofu init

# PASO 12: Verificación final antes de aplicar
echo "========================================"
echo "VERIFICACIÓN ANTES DE APLICAR"
echo "========================================"
echo "VMs existentes:"
virsh list --all
echo "Volúmenes existentes:"
virsh vol-list default
echo "Estado Terraform:"
tofu state list

# PASO 13: Aplicar Terraform
echo "========================================"
echo "APLICANDO TERRAFORM DESDE CERO TOTAL"
echo "========================================"
tofu apply -auto-approve

echo "========================================"
echo "LIMPIEZA AGRESIVA COMPLETADA"
echo "========================================"