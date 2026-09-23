#!/bin/bash

# Verificar parámetros
if [ "$#" -ne 4 ]; then
    echo "Uso: $0 <NOMBRE_VM> <NOMBRE_OVS> <VLAN_ID> <PUERTO_VNC>"
    exit 1
fi

VM_NAME="$1"
OVS_NAME="$2"
VLAN_ID="$3"
VNC_PORT="$4"

# Directorios e imagen base
IMAGE_DIR="/var/lib/tel141/images"
VM_DIR="/var/lib/tel141/vms"

BASE_IMAGE="${IMAGE_DIR}/cirros-0.5.1-x86_64-disk.img"
BASE_URL="http://download.cirros-cloud.net/0.5.1/cirros-0.5.1-x86_64-disk.img"

DISK_IMAGE="${VM_DIR}/${VM_NAME}.qcow2"
PID_FILE="/tmp/${VM_NAME}.pid"

# El parámetro puede darse como display VNC (1) o puerto TCP (5901)
if [ "$VNC_PORT" -ge 5900 ]; then
    VNC_DISPLAY=$((VNC_PORT - 5900))
else
    VNC_DISPLAY="$VNC_PORT"
fi

# Nombre reproducible de interfaz TAP
TAP_IF="tap${VLAN_ID}_${VNC_DISPLAY}"

echo "[+] Creando VM: $VM_NAME"
echo "[+] OVS: $OVS_NAME"
echo "[+] VLAN: $VLAN_ID"
echo "[+] TAP: $TAP_IF"
echo "[+] VNC: :$VNC_DISPLAY (TCP $((5900 + VNC_DISPLAY)))"

# Verificar que el bridge OVS exista
if ! sudo -n ovs-vsctl br-exists "$OVS_NAME" 2>/dev/null; then
    echo "Error: el bridge $OVS_NAME no existe."
    exit 1
fi

# Crear directorios necesarios
sudo -n mkdir -p "$IMAGE_DIR"
sudo -n mkdir -p "$VM_DIR"

# Descargar imagen base si no existe
if [ ! -f "$BASE_IMAGE" ]; then
    echo "[+] Imagen base no encontrada. Descargando CirrOS..."

    sudo -n wget -O "$BASE_IMAGE" "$BASE_URL"

    if [ $? -ne 0 ]; then
        echo "Error: no se pudo descargar la imagen base."
        exit 1
    fi
else
    echo "[+] Imagen base encontrada."
fi

# Evitar crear nuevamente una VM existente
if [ -f "$DISK_IMAGE" ]; then
    echo "Error: ya existe el disco de la VM $VM_NAME."
    echo "Elimine primero la VM con delete_vm.sh."
    exit 1
fi

# Crear disco delta basado en la imagen de CirrOS
echo "[+] Creando disco QCOW2..."

sudo -n qemu-img create \
    -f qcow2 \
    -F qcow2 \
    -b "$BASE_IMAGE" \
    "$DISK_IMAGE"

# Crear interfaz TAP
echo "[+] Creando interfaz TAP..."

sudo -n ip tuntap add dev "$TAP_IF" mode tap
sudo -n ip link set "$TAP_IF" up

# Conectar TAP al OVS y asignar VLAN
echo "[+] Conectando TAP a $OVS_NAME..."

sudo -n ovs-vsctl --may-exist add-port "$OVS_NAME" "$TAP_IF"
sudo -n ovs-vsctl set Port "$TAP_IF" tag="$VLAN_ID"

# Iniciar máquina virtual
echo "[+] Iniciando VM..."

sudo -n qemu-system-x86_64 \
    -name "$VM_NAME" \
    -enable-kvm \
    -m 512 \
    -smp 1 \
    -drive file="$DISK_IMAGE",format=qcow2 \
    -netdev tap,id=net0,ifname="$TAP_IF",script=no,downscript=no \
    -device e1000,netdev=net0 \
    -vnc 0.0.0.0:"$VNC_DISPLAY" \
    -pidfile "$PID_FILE" \
    -daemonize

# Verificar que QEMU haya iniciado
sleep 1

if sudo -n test -f "$PID_FILE"; then
    echo "[+] VM $VM_NAME creada correctamente."
    echo "[+] PID: $(sudo -n cat "$PID_FILE")"
    echo "[+] VNC TCP: $((5900 + VNC_DISPLAY))"
else
    echo "Error: la VM no pudo iniciarse."

    # Rollback básico
    sudo -n ovs-vsctl --if-exists del-port "$OVS_NAME" "$TAP_IF"
    sudo -n ip link delete "$TAP_IF" 2>/dev/null
    sudo -n rm -f "$DISK_IMAGE"

    exit 1
fi