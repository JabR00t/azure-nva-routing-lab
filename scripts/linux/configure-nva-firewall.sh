#!/usr/bin/env bash
set -euo pipefail

VNET_NETWORK="10.30.0.0/16"
WEB_NETWORK="10.30.10.0/24"
APP_NETWORK="10.30.20.0/24"
DATA_NETWORK="10.30.30.0/24"

echo "Enabling Linux IPv4 forwarding..."

sudo tee /etc/sysctl.d/99-nva-forwarding.conf >/dev/null <<'EOF'
net.ipv4.ip_forward=1
EOF

sudo sysctl --system

echo "Installing persistent iptables support..."

sudo apt-get update

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    iptables-persistent \
    tcpdump

echo "Removing previous forwarding rules..."

sudo iptables -F FORWARD
sudo iptables -t nat -F POSTROUTING

echo "Setting the default forwarding policy to DROP..."

sudo iptables -P FORWARD DROP

# Drop packets that connection tracking considers invalid.
sudo iptables -A FORWARD \
    -m conntrack \
    --ctstate INVALID \
    -j DROP

# Permit return packets for connections previously allowed.
sudo iptables -A FORWARD \
    -m conntrack \
    --ctstate ESTABLISHED,RELATED \
    -j ACCEPT

# Allow Web tier to initiate connections to Application tier on TCP 8443.
sudo iptables -A FORWARD \
    -s "${WEB_NETWORK}" \
    -d "${APP_NETWORK}" \
    -p tcp \
    --dport 8443 \
    -m conntrack \
    --ctstate NEW \
    -j ACCEPT

# Allow Application tier to initiate connections to Data tier on TCP 1433.
sudo iptables -A FORWARD \
    -s "${APP_NETWORK}" \
    -d "${DATA_NETWORK}" \
    -p tcp \
    --dport 1433 \
    -m conntrack \
    --ctstate NEW \
    -j ACCEPT

# Log direct Web-to-Data traffic.
sudo iptables -A FORWARD \
    -s "${WEB_NETWORK}" \
    -d "${DATA_NETWORK}" \
    -m limit \
    --limit 5/minute \
    --limit-burst 10 \
    -j LOG \
    --log-prefix "NVA_DROP_WEB_DATA " \
    --log-level 4

# Deny direct Web-to-Data traffic.
sudo iptables -A FORWARD \
    -s "${WEB_NETWORK}" \
    -d "${DATA_NETWORK}" \
    -j DROP

# Deny all other unapproved east-west traffic.
sudo iptables -A FORWARD \
    -s "${VNET_NETWORK}" \
    -d "${VNET_NETWORK}" \
    -j DROP

# Allow workload subnets to reach destinations outside the VNet.
sudo iptables -A FORWARD \
    -s "${WEB_NETWORK}" \
    ! -d "${VNET_NETWORK}" \
    -j ACCEPT

sudo iptables -A FORWARD \
    -s "${APP_NETWORK}" \
    ! -d "${VNET_NETWORK}" \
    -j ACCEPT

sudo iptables -A FORWARD \
    -s "${DATA_NETWORK}" \
    ! -d "${VNET_NETWORK}" \
    -j ACCEPT

# Translate internet-bound workload traffic to the NVA private address.
sudo iptables -t nat -A POSTROUTING \
    -s "${VNET_NETWORK}" \
    ! -d "${VNET_NETWORK}" \
    -j MASQUERADE

echo "Saving the firewall configuration..."

sudo netfilter-persistent save

echo
echo "IPv4 forwarding status:"
sysctl net.ipv4.ip_forward

echo
echo "FORWARD rules:"
sudo iptables -L FORWARD -n -v --line-numbers

echo
echo "NAT rules:"
sudo iptables -t nat -L POSTROUTING -n -v --line-numbers

echo
echo "NVA firewall configuration completed."