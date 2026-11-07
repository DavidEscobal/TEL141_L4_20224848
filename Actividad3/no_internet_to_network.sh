#!/bin/bash

# Verificar parámetros
if [ "$#" -ne 2 ]; then
    echo "Uso: $0 <VLAN_ID> <RED_CIDR>"
    exit 1
fi

VLAN_ID="$1"
RED_CIDR="$2"

VLAN_IF="vlan${VLAN_ID}"

echo "[+] Deshabilitando acceso a Internet para VLAN $VLAN_ID"
echo "[+] Red: $RED_CIDR"

# Verificar que la interfaz VLAN exista
if ! ip link show "$VLAN_IF" >/dev/null 2>&1; then
    echo "Error: la interfaz $VLAN_IF no existe."
    exit 1
fi

# Detectar interfaz de salida a Internet
WAN_IF=$(ip route show default | awk '/default/ {print $5; exit}')

if [ -z "$WAN_IF" ]; then
    echo "Error: no se encontró una interfaz con ruta por defecto."
    exit 1
fi

echo "[+] Interfaz de salida: $WAN_IF"

# Eliminar regla NAT / MASQUERADE si existe
while sudo -n iptables -t nat -C POSTROUTING \
    -s "$RED_CIDR" -o "$WAN_IF" -j MASQUERADE 2>/dev/null
do
    sudo -n iptables -t nat -D POSTROUTING \
        -s "$RED_CIDR" -o "$WAN_IF" -j MASQUERADE
done

# Eliminar regla de salida hacia Internet
while sudo -n iptables -C FORWARD \
    -i "$VLAN_IF" -o "$WAN_IF" \
    -s "$RED_CIDR" -j ACCEPT 2>/dev/null
do
    sudo -n iptables -D FORWARD \
        -i "$VLAN_IF" -o "$WAN_IF" \
        -s "$RED_CIDR" -j ACCEPT
done

# Eliminar regla de tráfico de retorno
while sudo -n iptables -C FORWARD \
    -i "$WAN_IF" -o "$VLAN_IF" \
    -d "$RED_CIDR" \
    -m conntrack --ctstate ESTABLISHED,RELATED \
    -j ACCEPT 2>/dev/null
do
    sudo -n iptables -D FORWARD \
        -i "$WAN_IF" -o "$VLAN_IF" \
        -d "$RED_CIDR" \
        -m conntrack --ctstate ESTABLISHED,RELATED \
        -j ACCEPT
done

echo "[+] Acceso a Internet deshabilitado para VLAN $VLAN_ID."