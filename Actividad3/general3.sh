
#!/bin/bash
set -Eeuo pipefail

ACTIVITY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ACTIVITY_DIR/../common.sh"

check_lab4_environment

DHCP_RANGE_100="${DHCP_RANGE_100:-192.168.0.50,192.168.0.150}"
DHCP_RANGE_200="${DHCP_RANGE_200:-192.168.2.50,192.168.2.150}"

echo "============================================"
echo " ACTIVIDAD 3: DHCP + SIN INTERNET"
echo "============================================"

# 1. Inicializar infraestructura.
prepare_cluster_nodes

# 2. Crear VLAN con DHCP.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/create_network_vlan.sh" \
    100 192.168.0.0/24 enabled "$DHCP_RANGE_100"

run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/create_network_vlan.sh" \
    200 192.168.2.0/24 enabled "$DHCP_RANGE_200"

# 3. Retirar las reglas de Internet.
disable_internet_if_possible "$SERVER3_HOST" \
    100 192.168.0.0/24

disable_internet_if_possible "$SERVER3_HOST" \
    200 192.168.2.0/24

# 4. Mantener las VLAN aisladas.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/no_routing_networks.sh" 100 200

# 5. Crear contenedores con DHCP.
create_container_remote "$SERVER1_HOST" \
    container_vlan100 100 dhcp "" 192.168.0.1

create_container_remote "$SERVER1_HOST" \
    container_vlan200 200 dhcp "" 192.168.2.1

# 6. Crear VMs.
create_lab_vms

echo ""
echo "[OK] ACTIVIDAD 3 CONFIGURADA."
echo "Validar DHCP, aislamiento y ausencia de Internet."
