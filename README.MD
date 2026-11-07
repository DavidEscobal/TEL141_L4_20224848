# Laboratorio 4 – Ingeniería de Redes Cloud (TEL141)

**Universidad:** Pontificia Universidad Católica del Perú (PUCP)  
**Curso:** Ingeniería de Redes Cloud  
**Periodo:** 2026-2  
**Repositorio:** TEL141_L4_20224848

## 1. Descripción del laboratorio

En este repositorio se encuentran los scripts desarrollados para el Laboratorio 4 del curso de Ingeniería de Redes Cloud.

El objetivo del laboratorio es configurar y analizar diferentes escenarios de redes virtualizadas utilizando Open vSwitch (OVS), VLAN, máquinas virtuales y herramientas de administración de redes en Linux.

Se trabajó con cuatro actividades, en las cuales se modificaron las condiciones de conectividad entre redes, considerando la asignación automática de direcciones IP mediante DHCP, el acceso a Internet y el enrutamiento entre VLAN.

Para facilitar la revisión y organización del código, los scripts se han agrupado según la actividad en la que se utilizan, manteniendo también una carpeta general con los scripts auxiliares.

## 2. Estructura del repositorio

El repositorio está organizado de la siguiente manera:

```text
TEL141_L4_20224848/
│
├── actividades/
│   ├── actividad1/
│   ├── actividad2/
│   ├── actividad3/
│   └── actividad4/
│
├── scripts/
│   ├── create_network_vlan.sh
│   ├── create_vm.sh
│   ├── delete_vm.sh
│   ├── init_master.sh
│   ├── init_worker.sh
│   ├── internet_to_network.sh
│   ├── no_internet_to_network.sh
│   ├── no_routing_networks.sh
│   └── routing_networks.sh
│
└── README.md
```

La carpeta `scripts` contiene los archivos auxiliares utilizados para configurar la infraestructura y realizar las diferentes operaciones de red.

Por otro lado, dentro de `actividades` se han colocado copias de los scripts correspondientes a cada escenario, de manera que sea más sencillo identificar qué archivos se utilizaron en cada parte del laboratorio.

## 3. Actividades desarrolladas

### Actividad 1: Redes aisladas con DHCP y salida a Internet

En esta actividad se configuraron redes VLAN independientes, habilitando el servicio DHCP para que los equipos conectados puedan obtener automáticamente una dirección IP.

También se configuraron las reglas necesarias para permitir la salida a Internet mediante NAT.

**Scripts utilizados:**
- `create_network_vlan.sh`: creación y configuración de las VLAN, incluyendo DHCP.
- `internet_to_network.sh`: configuración de NAT y reglas de reenvío para permitir el acceso a Internet.
- `no_routing_networks.sh`: configuración del aislamiento entre las VLAN.

### Actividad 2: Redes aisladas sin DHCP y con salida a Internet

En esta actividad se mantuvo la separación entre las redes virtuales, pero se deshabilitó el servicio DHCP.

Por ello, los equipos deben trabajar con direcciones IP configuradas manualmente. Asimismo, se mantuvo el acceso a Internet mediante las reglas de NAT.

**Scripts utilizados:**
- `create_network_vlan.sh`: creación de las VLAN con DHCP deshabilitado.
- `internet_to_network.sh`: habilitación del acceso a Internet.
- `no_routing_networks.sh`: mantenimiento del aislamiento entre las redes.

### Actividad 3: Redes aisladas con DHCP y sin salida a Internet

En este escenario se habilitó nuevamente DHCP para permitir la asignación automática de direcciones IP. Sin embargo, a diferencia de las actividades anteriores, se bloqueó la salida a Internet.

Se mantuvo el aislamiento entre las redes para evitar la comunicación directa entre las VLAN.

**Scripts utilizados:**
- `create_network_vlan.sh`: creación de las VLAN con DHCP habilitado.
- `no_internet_to_network.sh`: eliminación de las reglas que permiten la salida a Internet.
- `no_routing_networks.sh`: mantenimiento del aislamiento entre VLAN.

### Actividad 4: Enrutamiento entre redes aisladas

En la última actividad se trabajó con el enrutamiento entre las redes VLAN 100 y 200.

El propósito fue permitir la comunicación entre ambas redes mediante la configuración de reglas de reenvío en el servidor encargado del enrutamiento.

**Scripts utilizados:**
- `create_network_vlan.sh`: configuración de las interfaces VLAN, cuando corresponde preparar el escenario.
- `no_internet_to_network.sh`: mantenimiento de la restricción de acceso a Internet.
- `routing_networks.sh`: habilitación de la comunicación entre las redes VLAN.

## 4. Descripción de los scripts auxiliares

| Script | Descripción |
|---|---|
| `init_master.sh` | Inicializa la infraestructura de red del nodo principal. |
| `init_worker.sh` | Prepara la infraestructura de red de los nodos trabajadores. |
| `create_network_vlan.sh` | Crea y configura interfaces VLAN sobre Open vSwitch y permite habilitar o deshabilitar DHCP. |
| `create_vm.sh` | Permite crear máquinas virtuales utilizando QEMU/KVM. |
| `delete_vm.sh` | Realiza la eliminación de máquinas virtuales y sus recursos asociados. |
| `internet_to_network.sh` | Configura NAT y reglas de firewall para proporcionar acceso a Internet. |
| `no_internet_to_network.sh` | Retira las reglas que permiten el acceso a Internet. |
| `no_routing_networks.sh` | Configura el aislamiento entre las redes VLAN. |
| `routing_networks.sh` | Configura las reglas necesarias para permitir el enrutamiento entre VLAN. |

## 5. Tecnologías y herramientas utilizadas

Durante el desarrollo del laboratorio se utilizaron las siguientes tecnologías:

- **Linux:** sistema operativo utilizado para la configuración y administración de la infraestructura.
- **Open vSwitch (OVS):** administración de switches virtuales y segmentación mediante VLAN.
- **Bash:** elaboración de scripts para automatizar tareas de configuración.
- **iptables:** configuración de reglas de filtrado, reenvío de paquetes y NAT.
- **dnsmasq:** implementación del servicio DHCP.
- **QEMU/KVM:** creación y ejecución de máquinas virtuales.
- **Linux Network Namespaces y VETH:** aislamiento de entornos de red y conexión mediante interfaces virtuales.

## 6. Consideraciones para la ejecución

Antes de ejecutar los scripts se debe verificar que se encuentre preparada la infraestructura correspondiente y que los servicios y herramientas necesarios estén instalados.

Asimismo, algunos scripts requieren permisos de administrador para modificar interfaces de red, configurar reglas de firewall y administrar los recursos virtualizados.

Los parámetros de ejecución deben revisarse directamente en cada archivo, ya que algunos scripts reciben identificadores de VLAN, direcciones de red y opciones de configuración.

Es importante ejecutar las configuraciones en el servidor correspondiente, de acuerdo con la topología definida para cada actividad.

## 7. Conclusiones

El desarrollo de este laboratorio permitió trabajar con diferentes escenarios de redes virtualizadas, comprendiendo cómo se relacionan las VLAN, DHCP, NAT y el enrutamiento dentro de una infraestructura basada en Linux y Open vSwitch.

Además, el uso de scripts Bash permitió reutilizar configuraciones y reducir la ejecución manual de los procedimientos necesarios para preparar cada escenario.

Finalmente, se organizó el código en GitHub para facilitar su revisión, mantenimiento y reutilización en futuras actividades del curso.