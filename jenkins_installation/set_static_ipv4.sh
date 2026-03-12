#!/bin/bash

echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

cat <<EOF | tee /etc/netplan/50-cloud-init.yaml
network:
    ethernets:
        enp0s3:
            dhcp4: false
            addresses:
              - 192.168.1.200/24
            routes:
              - to: default
                via: 192.168.1.1
            nameservers:
              addresses: [8.8.8.8,8.8.4.4]
    version: 2
EOF
