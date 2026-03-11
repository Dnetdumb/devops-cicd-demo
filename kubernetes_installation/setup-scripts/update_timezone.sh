#!/bin/bash

## Install chrony Sync time and update timezone

apt install chrony -y

systemctl enable chronyd

sudo timedatectl set-timezone Asia/Ho_Chi_Minh
