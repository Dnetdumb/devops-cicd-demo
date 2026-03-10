#!/bin/bash

## Cài chrony Sync time và update timezone

apt install chrony -y

systemctl enable chronyd

sudo timedatectl set-timezone Asia/Ho_Chi_Minh
