#!/bin/bash

## Update /etc/sudoers on the nodes

echo "admin ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee -a /etc/sudoers
