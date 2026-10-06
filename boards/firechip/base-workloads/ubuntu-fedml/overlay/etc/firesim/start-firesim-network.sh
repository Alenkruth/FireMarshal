#!/usr/bin/env bash

# Detect network interface (eth0 or enXXX depending on kernel naming)
ETH_IFACE=$(ls /sys/class/net | grep -E '^eth|^en' | grep -v lo | head -1)
if [ -z "$ETH_IFACE" ]; then
    ETH_IFACE="eth0"
fi

mac=$(cat /sys/class/net/${ETH_IFACE}/address 2>/dev/null)
macpref=$(echo $mac | cut -c 1-8)
echo "start-firesim-network: iface=${ETH_IFACE} mac=${mac} prefix=${macpref}"

case "$macpref" in
    "00:12:6d")
        # FireSim IceNIC: MAC = 00:12:6d:00:<high>:<low>
        # Node index encodes into last two octets: node 0 -> ...00:01, node 1 -> ...00:02
        machigh=$(echo $mac | cut -c 13-14)
        maclow=$(echo $mac | cut -c 16-17)
        machigh_dec=$((16#$machigh))
        maclow_dec=$((16#$maclow))
        FIRESIM_IP="172.16.${machigh_dec}.${maclow_dec}"
        NODE_ID=$maclow_dec

        cat > /etc/netplan/50-cloud-init.yaml <<EOF
network:
  version: 2
  ethernets:
    ${ETH_IFACE}:
      addresses: [${FIRESIM_IP}/24]
      dhcp4: false
EOF
        echo "FireSim node ${NODE_ID}: assigned ${FIRESIM_IP}/24 on ${ETH_IFACE}"
        echo "$NODE_ID" > /var/firesim-node-id
        netplan apply 2>/dev/null || true
        ;;

    "52:54:00")
        # QEMU: use DHCP
        echo "QEMU mode: using DHCP on ${ETH_IFACE}"
        cp /etc/firesim/50-cloud-init-dhcp.yaml /etc/netplan/50-cloud-init.yaml
        netplan apply 2>/dev/null || true
        ;;

    *)
        echo "Unknown MAC prefix ${macpref}: falling back to DHCP"
        cp /etc/firesim/50-cloud-init-dhcp.yaml /etc/netplan/50-cloud-init.yaml
        netplan apply 2>/dev/null || true
        ;;
esac
