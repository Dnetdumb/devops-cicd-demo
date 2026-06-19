variable "proxmox_node" {
  description = "Proxmox Node name to deploy VM"
  type = string
  default = "pve"
}

variable "template_vm_id" {
  description = "VMID template"
  type = string
  default = "ubuntu-template"
}

variable "vm_count" {
  description = "Number of worker nodes"
  type = number
  default = 3
}

variable "vm_memory" {
  description = "Memory for each VM (MB)"
  type = number
  default = 2048
}

variable "vm_cpus" {
  description = "Number of CPUs for each VM"
  type = number
  default = 2
}

variable "vm_disk" {
  description = "Capacity of the VM"
  type = string
  default = "20G"
}

variable "storage" {
  description = "storage of the disk"
  type = string
  default = "local-lvm"
}

variable "ansible_user" {
  description = "User controller to execute ansible"
  type = string
  default = "ubuntu"
}

variable "master_subnet" {
  type = string
  default = "10.10.0.199"
}

variable "worker_subnet" {
  type = list(string)
  default = ["10.10.0.101", "10.10.0.102", "10.10.0.103"]
}
