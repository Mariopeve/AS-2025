#!/bin/bash

apt-get update && apt-get install -y iptables iproute2 dnsmasq

# activar routing
sysctl -w net.ipv4.ip_forward=1

# aplicar reglas
iptables-restore < /iptables.rules

# lanzar dnsmasq si lo usas
# dnsmasq

# mantener contenedor vivo
tail -f /dev/null