#!/bin/bash

## Update /etc/sudoers trên các Nodes

echo "admin ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
