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

IMAGE_DIR="/var/lib/tel141/images"
VM_DIR="/var/lib/tel141/vms"

BASE_IMAGE="${IMAGE_DIR}/cirros-0.5.1-x86_64-disk.img"
DISK_IMAGE="${VM_DIR}/${VM_NAME}.qcow2"
PID_FILE="/tmp/${VM_NAME}.pid"

# Determinar display VNC de la misma forma que create_vm.sh
if [ "$VNC_PORT" -ge 5900 ]; then
    VNC_DISPLAY=$((VNC_PORT - 5900))
else
    VNC_DISPLAY="$VNC_PORT"
fi

# Reconstruir nombre de interfaz TAP
TAP_IF="tap${VLAN_ID}_${VNC_DISPLAY}"

echo "[+] Eliminando VM: $VM_NAME"

# 1. Detener la VM
if sudo -n test -f "$PID_FILE"; then
    VM_PID=$(sudo -n cat "$PID_FILE")

    if sudo -n kill -0 "$VM_PID" 2>/dev/null; then
        echo "[+] Deteniendo proceso QEMU PID $VM_PID"
        sudo -n kill "$VM_PID"

        # Esperar brevemente a que termine
        sleep 2

        # Forzar cierre si sigue activo
        if sudo -n kill -0 "$VM_PID" 2>/dev/null; then
            sudo -n kill -9 "$VM_PID"
        fi
    fi

    sudo -n rm -f "$PID_FILE"
else
    echo "[!] No se encontró PID file para $VM_NAME."
fi

# 2. Eliminar puerto TAP del OVS
echo "[+] Eliminando $TAP_IF de $OVS_NAME"

sudo -n ovs-vsctl --if-exists del-port "$OVS_NAME" "$TAP_IF"

# 3. Eliminar interfaz TAP
if ip link show "$TAP_IF" >/dev/null 2>&1; then
    sudo -n ip link set "$TAP_IF" down
    sudo -n ip link delete "$TAP_IF"
fi

# 4. Eliminar disco delta de la VM
if [ -f "$DISK_IMAGE" ]; then
    echo "[+] Eliminando disco $DISK_IMAGE"
    sudo -n rm -f "$DISK_IMAGE"
else
    echo "[!] Disco de la VM no encontrado."
fi

# 5. Verificar si la imagen base aún tiene discos delta
DELTA_COUNT=0

if [ -d "$VM_DIR" ]; then
    for disk in "$VM_DIR"/*.qcow2; do

        [ -e "$disk" ] || continue

        BACKING_FILE=$(sudo -n qemu-img info "$disk" 2>/dev/null \
            | awk -F': ' '/backing file:/ {print $2}' \
            | awk '{print $1}')

        if [ "$BACKING_FILE" = "$BASE_IMAGE" ]; then
            DELTA_COUNT=$((DELTA_COUNT + 1))
        fi
    done
fi

# 6. Eliminar imagen base si ya no tiene discos delta
if [ "$DELTA_COUNT" -eq 0 ] && [ -f "$BASE_IMAGE" ]; then
    echo "[+] La imagen base ya no tiene discos delta asociados."
    echo "[+] Eliminando imagen base..."
    sudo -n rm -f "$BASE_IMAGE"
else
    echo "[+] Discos delta restantes: $DELTA_COUNT"
fi

echo "[+] VM $VM_NAME eliminada correctamente."