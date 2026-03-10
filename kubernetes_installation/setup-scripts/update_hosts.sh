#!/bin/bash

#Run this command on Master-CP1

cat <<EOF | tee /etc/hosts
127.0.0.1 localhost
192.168.1.199 Master-CP1 k8s-api.lab.local
192.168.1.101 Worker-Node1
192.168.1.102 Worker-Node2
EOF

#Run this command on Worker-Node1

cat <<EOF | tee /etc/hosts
127.0.0.1 localhost
192.168.1.199 Master-CP1 k8s-api.lab.local
192.168.1.101 Worker-Node1
192.168.1.102 Worker-Node2
EOF

#Run this command on Worker-Node2

cat <<EOF | tee /etc/hosts
127.0.0.1 localhost
192.168.1.199 Master-CP1 k8s-api.lab.local
192.168.1.101 Worker-Node1
192.168.1.102 Worker-Node2
EOF
