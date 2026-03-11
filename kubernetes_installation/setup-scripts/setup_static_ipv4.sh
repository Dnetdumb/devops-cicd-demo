#!/bin/bash

#Run this command on Master-CP1

echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

cat <<EOF | tee /etc/netplan/50-cloud-init.yaml
network:
    ethernets:
        enp0s3:
            dhcp4: false
            addresses:
              - 192.168.1.199/24
            routes:
              - to: default
                via: 192.168.1.1
            nameservers:
              addresses: [8.8.8.8,8.8.4.4]
    version: 2
EOF

#Run this command on Worker-Node1

echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

cat <<EOF | tee /etc/netplan/50-cloud-init.yaml
network:
    ethernets:
        enp0s3:
            dhcp4: false
            addresses:
              - 192.168.1.101/24
            routes:
              - to: default
                via: 192.168.1.1
            nameservers:
              addresses: [8.8.8.8,8.8.4.4]
    version: 2
EOF

#Run this command on Worker-Node2

echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg

cat <<EOF | tee /etc/netplan/50-cloud-init.yaml
network:
    ethernets:
        enp0s3:
            dhcp4: false
            addresses:
              - 192.168.1.102/24
            routes:
              - to: default
                via: 192.168.1.1
            nameservers:
              addresses: [8.8.8.8,8.8.4.4]
    version: 2
EOF
