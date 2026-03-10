#!/bin/bash

ssh admin@192.168.1.199 "sudo hostnamectl set-hostname Master-CP1"

ssh admin@192.168.1.101 "sudo hostnamectl set-hostname Worker-Node1"

ssh admin@192.168.1.102 "sudo hostnamectl set-hostname Worker-Node2"
