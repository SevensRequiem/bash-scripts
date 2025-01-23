#!/bin/bash

INTERFACE=$(ip -o link show | awk -F': ' '{print $2}' | grep -v 'lo' | head -n 1)

if [ -z "$INTERFACE" ]; then
    echo "No active network interface found!"
    exit 1
fi

echo "Detected network interface: $INTERFACE"

CURRENT_IP=$(ip addr show $INTERFACE | grep -oP 'inet \K[\d.]+')
echo "Current IP address: $CURRENT_IP"

read -p "Enter the new static IP address (current IP is $CURRENT_IP): " NEW_IP
if [ -z "$NEW_IP" ]; then
    echo "No new IP address provided. Exiting..."
    exit 1
fi

read -p "Enter the subnet mask (default is 255.255.255.0): " NETMASK
NETMASK=${NETMASK:-255.255.255.0}

CURRENT_GATEWAY=$(ip route show default | grep -oP 'default via \K[\d.]+')
read -p "Enter the gateway (current gateway is $CURRENT_GATEWAY): " GATEWAY
GATEWAY=${GATEWAY:-$CURRENT_GATEWAY}

read -p "Enter DNS server 1 (default is 1.1.1.1): " DNS1
DNS1=${DNS1:-1.1.1.1}

read -p "Enter DNS server 2 (default is 1.0.0.1): " DNS2
DNS2=${DNS2:-1.0.0.1}

NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"

if [ ! -f "$NETPLAN_FILE" ]; then
    echo "Netplan configuration file not found!"
    exit 1
fi

cp $NETPLAN_FILE "${NETPLAN_FILE}.bak"
echo "Backup of current Netplan configuration created: ${NETPLAN_FILE}.bak"

cat > $NETPLAN_FILE <<EOL
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      dhcp4: no
      addresses:
        - $NEW_IP/24
      gateway4: $GATEWAY
      nameservers:
        addresses:
          - $DNS1
          - $DNS2
EOL

echo "Applying new network configuration..."
netplan apply

echo "New IP configuration:"
ip addr show $INTERFACE

echo "Static IP configuration applied."

echo "Start misc..."

apt install net-tools

apt install curl

ssh-import-id-gh SevensRequiem
