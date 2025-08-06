 # Crear un nuevo volumen con permisos correctos desde el inicio                                                       ─╯
tofu destroy -auto-approve

# Eliminar archivos existentes
sudo rm -f /var/lib/libvirt/images/ubuntu2404-tpl.qcow2
sudo rm -f /var/lib/libvirt/images/cloudinit-vm.iso

# Descargar manualmente la imagen con permisos correctos
cd /var/lib/libvirt/images/
sudo wget -O ubuntu2404-tpl.qcow2 https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img
sudo chown libvirt-qemu:libvirt-qemu ubuntu2404-tpl.qcow2
sudo chmod 644 ubuntu2404-tpl.qcow2

# Volver al directorio de trabajo y aplicar
cd -
tofu apply -auto-approve