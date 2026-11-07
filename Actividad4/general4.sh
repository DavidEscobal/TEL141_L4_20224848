
#!/bin/bash
set -Eeuo pipefail

ACTIVITY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ACTIVITY_DIR/../common.sh"

check_lab4_environment

DHCP_RANGE_200="${DHCP_RANGE_200:-192.168.2.50,192.168.2.150}"

echo "============================================"
echo " ACTIVIDAD 4: ROUTING ENTRE VLAN"
echo "============================================"

# 1. Inicializar el Headnode.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/init_master.sh" ens4

# 2. Crear VLAN 100 sin DHCP.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/create_network_vlan.sh" \
    100 192.168.0.0/24 disabled

# 3. Crear VLAN 200 con DHCP.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/create_network_vlan.sh" \
    200 192.168.2.0/24 enabled "$DHCP_RANGE_200"

# 4. Asegurar que no exista salida a Internet.
disable_internet_if_possible "$SERVER3_HOST" \
    100 192.168.0.0/24

disable_internet_if_possible "$SERVER3_HOST" \
    200 192.168.2.0/24

# 5. Limpiar reglas de routing anteriores.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/no_routing_networks.sh" 100 200

# 6. Habilitar comunicación entre VLAN.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/routing_networks.sh" 100 200

echo ""
echo "[OK] ACTIVIDAD 4 CONFIGURADA."
echo "Routing habilitado entre VLAN 100 y VLAN 200."
