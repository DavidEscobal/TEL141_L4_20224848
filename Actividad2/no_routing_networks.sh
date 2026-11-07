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

echo "[+] Deshabilitando routing entre VLAN $VLAN1 y VLAN $VLAN2"

# Eliminar regla VLAN1 -> VLAN2 si existe
while sudo -n iptables -C FORWARD \
    -i "$IF1" -o "$IF2" -j ACCEPT 2>/dev/null
do
    sudo -n iptables -D FORWARD \
        -i "$IF1" -o "$IF2" -j ACCEPT
done

# Eliminar regla VLAN2 -> VLAN1 si existe
while sudo -n iptables -C FORWARD \
    -i "$IF2" -o "$IF1" -j ACCEPT 2>/dev/null
do
    sudo -n iptables -D FORWARD \
        -i "$IF2" -o "$IF1" -j ACCEPT
done

echo "[+] Routing deshabilitado entre VLAN $VLAN1 y VLAN $VLAN2."