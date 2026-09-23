#!/bin/bash

# Verificar cantidad de parámetros
if [ "$#" -lt 3 ]; then
    echo "Uso: $0 <VLAN_ID> <RED_CIDR> <DHCP enabled|disabled> [RANGO_DHCP]"
    exit 1
fi

VLAN_ID="$1"
RED_CIDR="$2"
DHCP="$3"
DHCP_RANGE="$4"

BRIDGE="br-int"
VLAN_IF="vlan${VLAN_ID}"
NAMESPACE="ns${VLAN_ID}"
VETH_HOST="vh${VLAN_ID}"
VETH_NS="vn${VLAN_ID}"

# Verificar VLAN válida
if ! [[ "$VLAN_ID" =~ ^[0-9]+$ ]] || [ "$VLAN_ID" -lt 1 ] || [ "$VLAN_ID" -gt 4094 ]; then
    echo "Error: VLAN ID inválido."
    exit 1
fi

# Separar dirección IP y prefijo
NETWORK_IP="${RED_CIDR%/*}"
PREFIX="${RED_CIDR#*/}"

# Convertir una IPv4 a número entero
ip_to_int() {
    IFS='.' read -r a b c d <<< "$1"
    echo $(( (10#$a << 24) + (10#$b << 16) + (10#$c << 8) + 10#$d ))
}

# Convertir número entero a IPv4
int_to_ip() {
    local ip=$1

    printf "%d.%d.%d.%d" \
        $(( (ip >> 24) & 255 )) \
        $(( (ip >> 16) & 255 )) \
        $(( (ip >> 8) & 255 )) \
        $(( ip & 255 ))
}

NETWORK_INT=$(ip_to_int "$NETWORK_IP")

# Primera dirección utilizable = gateway
GATEWAY=$(int_to_ip $((NETWORK_INT + 1)))

# Segunda dirección utilizable = servidor DHCP
DHCP_IP=$(int_to_ip $((NETWORK_INT + 2)))

echo "[+] Configurando VLAN $VLAN_ID"
echo "[+] Red: $RED_CIDR"
echo "[+] Gateway: $GATEWAY"

# Verificar que br-int exista
if ! sudo -n ovs-vsctl br-exists "$BRIDGE" 2>/dev/null; then
    echo "Error: el bridge $BRIDGE no existe."
    echo "Ejecute primero init_master.sh."
    exit 1
fi

# Crear interfaz interna para la VLAN
sudo -n ovs-vsctl --may-exist add-port "$BRIDGE" "$VLAN_IF" \
    -- set Interface "$VLAN_IF" type=internal \
    -- set Port "$VLAN_IF" tag="$VLAN_ID"

# Configurar dirección gateway
sudo -n ip addr flush dev "$VLAN_IF"
sudo -n ip addr add "${GATEWAY}/${PREFIX}" dev "$VLAN_IF"
sudo -n ip link set "$VLAN_IF" up

case "$DHCP" in

    enabled|enable|true|yes|1)

        if [ -z "$DHCP_RANGE" ]; then
            echo "Error: debe indicar el rango DHCP."
            exit 1
        fi

        echo "[+] DHCP habilitado"
        echo "[+] Dirección del servidor DHCP: $DHCP_IP"

        # Crear namespace si no existe
        if ! sudo -n ip netns list | awk '{print $1}' | grep -qx "$NAMESPACE"; then
            sudo -n ip netns add "$NAMESPACE"
        fi

        # Crear par veth si todavía no existe
        if ! ip link show "$VETH_HOST" >/dev/null 2>&1; then
            sudo -n ip link add "$VETH_HOST" type veth peer name "$VETH_NS"
            sudo -n ip link set "$VETH_NS" netns "$NAMESPACE"
        fi

        # Conectar el veth del host a la VLAN
        sudo -n ovs-vsctl --may-exist add-port "$BRIDGE" "$VETH_HOST"
        sudo -n ovs-vsctl set Port "$VETH_HOST" tag="$VLAN_ID"

        sudo -n ip link set "$VETH_HOST" up

        # Configurar interfaz dentro del namespace
        sudo -n ip netns exec "$NAMESPACE" ip link set lo up
        sudo -n ip netns exec "$NAMESPACE" ip addr flush dev "$VETH_NS"
        sudo -n ip netns exec "$NAMESPACE" \
            ip addr add "${DHCP_IP}/${PREFIX}" dev "$VETH_NS"

        sudo -n ip netns exec "$NAMESPACE" ip link set "$VETH_NS" up

        # Archivo PID único para dnsmasq
        PIDFILE="/run/dnsmasq-vlan${VLAN_ID}.pid"

        # Detener una instancia anterior si existiera
        if sudo -n test -f "$PIDFILE"; then
            OLD_PID=$(sudo -n cat "$PIDFILE")
            sudo -n kill "$OLD_PID" 2>/dev/null || true
            sudo -n rm -f "$PIDFILE"
        fi

        # Iniciar servidor DHCP
        sudo -n ip netns exec "$NAMESPACE" dnsmasq \
            --interface="$VETH_NS" \
            --bind-interfaces \
            --port=0 \
            --dhcp-range="${DHCP_RANGE},12h" \
            --dhcp-option=3,"$GATEWAY" \
            --pid-file="$PIDFILE"

        echo "[+] DHCP configurado correctamente."
        ;;

    disabled|disable|false|no|0)

        echo "[+] DHCP deshabilitado."

        # Eliminar recursos DHCP anteriores si existieran
        PIDFILE="/run/dnsmasq-vlan${VLAN_ID}.pid"

        if sudo -n test -f "$PIDFILE"; then
            OLD_PID=$(sudo -n cat "$PIDFILE")
            sudo -n kill "$OLD_PID" 2>/dev/null || true
            sudo -n rm -f "$PIDFILE"
        fi

        sudo -n ovs-vsctl --if-exists del-port "$VETH_HOST"

        if sudo -n ip netns list | awk '{print $1}' | grep -qx "$NAMESPACE"; then
            sudo -n ip netns del "$NAMESPACE"
        fi
        ;;

    *)
        echo "Error: DHCP debe ser 'enabled' o 'disabled'."
        exit 1
        ;;
esac

echo "[+] VLAN $VLAN_ID configurada correctamente."