#!/bin/bash
# Proof of concept script for monitoring Docker container network traffic using tshark
# This is just a test. Don't use this for anything important.

# Check for container name/ID argument
if [ -z "$1" ]; then
    echo "Usage: $0 <container_name_or_id>"
    exit 1
fi

CONTAINER="$1"
CAPTURE_FILE="capture_${CONTAINER}.pcap"

# Get the PID of the container
PID=$(docker inspect -f '{{.State.Pid}}' "$CONTAINER")
if [ -z "$PID" ]; then
    echo "Error: Could not find container PID."
    exit 1
fi

# Find the veth interface on the host side
VETH_IFACE=$(sudo ls -l /sys/class/net | grep "veth" | while read -r line; do
    IFACE=$(echo "$line" | awk '{print $9}')
    PEER_IFINDEX=$(cat /sys/class/net/"$IFACE"/ifindex 2>/dev/null)
    CONTAINER_IFINDEX=$(sudo nsenter -t "$PID" -n ip link | grep "@if${PEER_IFINDEX}" | wc -l)
    if [ "$CONTAINER_IFINDEX" -gt 0 ]; then
        echo "$IFACE"
        break
    fi
done)

if [ -z "$VETH_IFACE" ]; then
    echo "Error: Could not find veth interface for container $CONTAINER"
    exit 1
fi

echo "Capturing traffic on interface: $VETH_IFACE"
echo "Saving to: $CAPTURE_FILE"

# Run tshark
sudo tshark -i "$VETH_IFACE" -w "$CAPTURE_FILE"
