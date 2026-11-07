#!/bin/bash

# Verificar que se haya recibido al menos una interfaz
if [ "$#" -lt 1 ]; then
    echo "Uso: $0 <interfaz1> [interfaz2] ..."
    exit 1
fi

BRIDGE="br-int"

echo "[+] Inicializando nodo worker..."

# Crear br-int si no existe
sudo -n ovs-vsctl --may-exist add-br "$BRIDGE"

# Conectar las interfaces recibidas al bridge
for interfaz in "$@"; do

    # Verificar que la interfaz exista
    if ! ip link show "$interfaz" >/dev/null 2>&1; then
        echo "Error: la interfaz $interfaz no existe."
        exit 1
    fi

    echo "[+] Agregando interfaz $interfaz a $BRIDGE"

    sudo -n ovs-vsctl --may-exist add-port "$BRIDGE" "$interfaz"
done

echo "[+] Nodo worker configurado correctamente."