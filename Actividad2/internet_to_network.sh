#!/bin/bash

# Verificar parámetros
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <VLAN_ID> <RED_CIDR>"
    exit 1
fi

VLAN_ID="$1"
RED_CIDR="$2"

VLAN_IF="vlan${VLAN_ID}"

echo "[+] Habilitando acceso a Internet para VLAN $VLAN_ID"
echo "[+] Red: $RED_CIDR"

# Verificar que la interfaz VLAN exista
if ! ip link show "$VLAN_IF" >/dev/null 2>&1; then
    echo "Error: la interfaz $VLAN_IF no existe."
    echo "Ejecute primero create_network_vlan.sh."
    exit 1
fi

# Detectar automáticamente la interfaz con salida a Internet
WAN_IF=$(ip route show default | awk '/default/ {print $5; exit}')

if [ -z "$WAN_IF" ]; then
    echo "Error: no se encontró una interfaz con ruta por defecto."
    exit 1
fi

echo "[+] Interfaz de salida: $WAN_IF"

# Regla NAT / MASQUERADE
sudo -n iptables -t nat -C POSTROUTING \
    -s "$RED_CIDR" -o "$WAN_IF" -j MASQUERADE 2>/dev/null || \
sudo -n iptables -t nat -A POSTROUTING \
    -s "$RED_CIDR" -o "$WAN_IF" -j MASQUERADE

# Permitir tráfico desde la VLAN hacia Internet
sudo -n iptables -C FORWARD \
    -i "$VLAN_IF" -o "$WAN_IF" \
    -s "$RED_CIDR" -j ACCEPT 2>/dev/null || \
sudo -n iptables -A FORWARD \
    -i "$VLAN_IF" -o "$WAN_IF" \
    -s "$RED_CIDR" -j ACCEPT

# Permitir tráfico de respuesta hacia la VLAN
sudo -n iptables -C FORWARD \
    -i "$WAN_IF" -o "$VLAN_IF" \
    -d "$RED_CIDR" \
    -m conntrack --ctstate ESTABLISHED,RELATED \
    -j ACCEPT 2>/dev/null || \
sudo -n iptables -A FORWARD \
    -i "$WAN_IF" -o "$VLAN_IF" \
    -d "$RED_CIDR" \
    -m conntrack --ctstate ESTABLISHED,RELATED \
    -j ACCEPT

echo "[+] Acceso a Internet habilitado para VLAN $VLAN_ID."