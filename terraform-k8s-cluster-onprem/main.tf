# =========== Define Plugin Providers ============
terraform {
  required_providers {
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.2-rc06"
    }
    time = {
      source = "hashicorp/time"
    }
    local = {
      source = "hashicorp/local"
    }
  } 
}

# =========== Connect Proxmox API Server ============
provider "proxmox" {
  pm_api_url      = "https://192.168.2.150:8006/api2/json"
  pm_user         = "root@pam"
  pm_password     = "<PASSWDROOTHERE>"
  pm_log_enable	  = true
  pm_log_file	  = "terraform-plugin-proxmox.log"
  pm_debug	  = true
  pm_log_levels = {
    _default = "debug"
    _capturelog = ""
  }
  pm_tls_insecure = true
}

# =========== Define Master Nodes ============
resource "proxmox_vm_qemu" "masters" {
  count = 1
  name = "VM-MASTER1"
  target_node = var.proxmox_node

  clone = var.template_vm_id
  full_clone = true
  
  memory = var.vm_memory
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"
      
  cpu {
    cores = var.vm_cpus
  }  
 
  disk {
    slot = "scsi0"
    size = var.vm_disk
    storage = var.storage
    type = "disk"
  }
  
  # Disk of cloud-init
  disk {
    slot = "ide2"
    size = "4M"
    storage = var.storage
    type = "cloudinit"
  }

  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }
  
  serial {
    id = 0
    type = "socket"
  }
  
  vga {
    type = "serial0"
  }
  

  #Cloud-init override
  ipconfig0 = "ip=${var.master_subnet}/24,gw=10.10.0.1"
  cicustom = "user=local:snippets/custom-cloudinit.yaml"
  #agent = 1
}

# =========== Define Worker Nodes ============
resource "proxmox_vm_qemu" "workers" {
  count = var.vm_count
  name = "VM-WORKER${count.index + 1}"
  target_node = var.proxmox_node
  clone = var.template_vm_id
  full_clone = true  

  memory = var.vm_memory
  scsihw = "virtio-scsi-pci"
  bootdisk = "scsi0"

  cpu {
    cores = var.vm_cpus
  }

  disk {
    slot = "scsi0"
    size = var.vm_disk
    storage = var.storage
    type = "disk"
  }

  # Disk of cloud-init
  disk {
    slot = "ide2"
    size = "4M"
    storage = var.storage
    type = "cloudinit"
  }

  network {
    id = 0
    model = "virtio"
    bridge = "vmbr0"
  }
  
  serial {
    id = 0
    type = "socket"
  }

  vga {
    type = "serial0"
  }
  
  #Cloud-init override
  ipconfig0 = "ip=10.10.0.${count.index + 101}/24,gw=10.10.0.1"
  cicustom = "user=local:snippets/custom-cloudinit.yaml"
  #agent = 1
}

# =========== Wait for Nodes boot ============
resource "time_sleep" "wait_for_boot" {
  depends_on = [
    proxmox_vm_qemu.masters,
    proxmox_vm_qemu.workers
  ]

  create_duration = "120s"
}

# =========== Output inventory for ansible ============
resource "local_file" "ansible_inventory" {
  depends_on = [time_sleep.wait_for_boot]

  content = templatefile("${path.module}/templates/inventory.tpl", {
    master_ip = var.master_subnet 
    worker_ip = var.worker_subnet
    ssh_user = var.ansible_user
  })

  filename = "${path.module}/k8s-ansible/inventory/hosts.ini"
}

# =========== Execute ansible playbooks ============
resource "null_resource" "ansible-k8s" {
  depends_on = [local_file.ansible_inventory]

  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/k8s-ansible/inventory/hosts.ini ${path.module}/k8s-ansible/site.yml"
  }
}

# =========== Wait for API server start and nodes ready ============
resource "time_sleep" "wait_for_APIserver" {
  depends_on = [null_resource.ansible-k8s]

  create_duration = "90s"
}

#=========== Check K8s state and output file ============
resource "null_resource" "k8s-state" {
  depends_on = [
    local_file.ansible_inventory,
    time_sleep.wait_for_APIserver
  ]
  
  provisioner "local-exec" {
    command = "ansible-playbook -i ${path.module}/k8s-ansible/inventory/hosts.ini ${path.module}/k8s-ansible/k8s-state.yml"
  }
 
  provisioner "local-exec" {
    command = "cat ./k8s-ansible/k8s-cluster-output.txt"
  } 
}


