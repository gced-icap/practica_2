#!/bin/bash
set -eux

ip=$1

# configure apt for non-interactive mode
export DEBIAN_FRONTEND=noninteractive

# show the proxmox web address
cat <<EOF
access the proxmox web interface at:
    https://$ip:8006/
EOF