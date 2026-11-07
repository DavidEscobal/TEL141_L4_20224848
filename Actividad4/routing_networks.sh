#!/bin/bash

# Verificar parámetros
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <VLAN_ID_1> <VLAN_ID_2>"
    exit 1
fi

VLAN1="$1"
VLAN2="$2"

IF1="vlan${VLAN1}"
IF2="vlan${VLAN2}"

echo "[+] Habilitando routing entre VLAN $VLAN1 y VLAN $VLAN2"

# Verificar que ambas interfaces VLAN existan
if ! ip link show "$IF1" >/dev/null 2>&1; then
    echo "Error: la interfaz $IF1 no existe."
    exit 1
fi

if ! ip link show "$IF2" >/dev/null 2>&1; then
    echo "Error: la interfaz $IF2 no existe."
    exit 1
fi

# Verificar que IPv4 forwarding esté habilitado
if [ "$(sysctl -n net.ipv4.ip_forward)" -ne 1 ]; then
    echo "Error: IPv4 forwarding no está habilitado."
    echo "Ejecute primero init_master.sh."
    exit 1
fi

# Permitir tráfico VLAN1 -> VLAN2
sudo -n iptables -C FORWARD \
    -i "$IF1" -o "$IF2" -j ACCEPT 2>/dev/null || \
sudo -n iptables -A FORWARD \
    -i "$IF1" -o "$IF2" -j ACCEPT

# Permitir tráfico VLAN2 -> VLAN1
sudo -n iptables -C FORWARD \
    -i "$IF2" -o "$IF1" -j ACCEPT 2>/dev/null || \
sudo -n iptables -A FORWARD \
    -i "$IF2" -o "$IF1" -j ACCEPT

echo "[+] Routing habilitado entre VLAN $VLAN1 y VLAN $VLAN2."