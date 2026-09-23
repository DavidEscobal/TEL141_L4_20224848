#!/bin/bash

# Verificar que se haya recibido al menos una interfaz
if [ "$#" -lt 1 ]; then
    echo "Uso: $0 <interfaz1> [interfaz2] ..."
    exit 1
fi

echo "[+] Inicializando nodo master..."

# Crear el bridge br-int si todavía no existe
sudo ovs-vsctl --may-exist add-br br-int

# Conectar al bridge las interfaces recibidas como parámetros
for interfaz in "$@"; do
    echo "[+] Agregando interfaz $interfaz a br-int"
    sudo ovs-vsctl --may-exist add-port br-int "$interfaz"
done

# Activar IPv4 forwarding
sudo sysctl -w net.ipv4.ip_forward=1

# Bloquear por defecto el tráfico reenviado
sudo iptables -P FORWARD DROP

echo "[+] Nodo master configurado correctamente."