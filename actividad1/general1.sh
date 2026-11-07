
#!/bin/bash
set -Eeuo pipefail

ACTIVITY_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$ACTIVITY_DIR/../common.sh"

check_lab4_environment

echo "============================================"
echo " ACTIVIDAD 2: SIN DHCP + INTERNET"
echo "============================================"

# 1. Inicializar infraestructura.
prepare_cluster_nodes

# 2. Crear VLAN sin DHCP.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/create_network_vlan.sh" \
    100 192.168.0.0/24 disabled

run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/create_network_vlan.sh" \
    200 192.168.2.0/24 disabled

# 3. Mantener aislamiento entre VLAN.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/no_routing_networks.sh" 100 200

# 4. Habilitar Internet.
run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/internet_to_network.sh" \
    100 192.168.0.0/24

run_remote_script "$SERVER3_HOST" \
    "$SCRIPTS_DIR/internet_to_network.sh" \
    200 192.168.2.0/24

# 5. Crear contenedores con IP estática.
create_container_remote "$SERVER1_HOST" \
    container_vlan100 100 static \
    192.168.0.10/24 192.168.0.1

create_container_remote "$SERVER1_HOST" \
    container_vlan200 200 static \
    192.168.2.10/24 192.168.2.1

# 6. Crear las VMs.
create_lab_vms

echo ""
echo "[OK] ACTIVIDAD 2 CONFIGURADA."
echo ""
echo "IMPORTANTE: Configurar manualmente las IP de las VMs"
echo "desde sus consolas VNC:"
echo ""
echo "VM VLAN100:"
echo "sudo ip addr add 192.168.0.20/24 dev eth0"
echo "sudo ip route replace default via 192.168.0.1"
echo ""
echo "VM VLAN200:"
echo "sudo ip addr add 192.168.2.20/24 dev eth0"
echo "sudo ip route replace default via 192.168.2.1"
