# Install and setup Cluster K8s with Terraform + Ansible on Proxmox Server
```bash
# Terraform (IaC): Build Infra (Create VMs)
# Ansible 	 : Config

# WorkFlows:
Host: 192.168.2.34 (Terraform and Ubuntu Control Node)
	|
	|
 Terraform apply (Clone 3 VM and run asible)
	|
	|
Proxmox Server: 
- eno1: 192.168.2.150/24 (network management)
- vmbr0: 10.10.0.1/24 (internal network for 3 nodes)
	--> Terraform apply (create 1 Master, 2 Worker nodes)
        --> Ansible install on 3 nodes: dependencies, kubelet, kubectl, kubeadm, join cluster, ...
	         
```
## First, we have to build a Proxmox Server and prapare a cloud image (UbuntuServer2204)
```bash
Reference sources:
https://www.proxmox.com/en/downloads (Proxmox)
https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img (qcow2 format)
```
#### Config DHCP for vmbr0
```bash
apt install dnsmasq -y

cat <<EOF > /etc/dnsmasq.d/vmbr0.conf
interface=vmbr0
dhcp-range=10.10.0.100,10.10.0.200,12h
EOF

systemctl restart dnsmasq
```

#### Download cloud image on Proxmox Server and setup NAT for vmbr0
```bash
cd /var/lib/vz/template/iso/
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/^#\(net.ipv4.ip_forward=1\)/\1/' /etc/sysctl.conf

sysctl -p
# Nat Rule
iptables -t nat -A POSTROUTING -s 10.10.0.0/24 -o eno1 -j MASQUERADE
# Forward rule 1
iptables -A FORWARD -i vmbr0 -o eno1 -j ACCEPT
# Forward rule 2
iptables -A FORWARD -i eno1 -o vmbr0 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Workflows:

VM 10.10.0.x -> Internet -> touch "Forward rule 1"
	|
	|
"NAT rule" change ip 10.10.0.x into IP source of eno1
	|
	|
Internet reply back -> touch "Forward rule 2" -> VM 10.10.0.x
```
#### Setup a custom-cloudinit.yaml files
```bash
#cloud-config
hostname: ubuntu-base
timezone: Asia/Ho_Chi_Minh

users:
  - name: ubuntu
    gecos: Ubuntu User
    sudo: ALL=(ALL) NOPASSWD:ALL
    groups: sudo
    shell: /bin/bash
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAA...
    lock_passwd: false

ssh_pwauth: true
chpasswd:
  list: |
    ubuntu:P@ss!sMySecret123
  expire: False

runcmd:
  - echo "Cloudinit finished !!!"
```

#### Create VM from cloud image with "custom-cloudinit.yaml"
```bash
qm create 9000 --name ubuntu-template --memory 1024 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --cicustom "user=local:snippets/custom-cloudinit.yaml"
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --ipconfig0 ip=dhcp
qm set 9000 --onboot 1
```
#### Convert VM to template
```bash
qm template 9000
# check:
qm config 9000
boot: c
bootdisk: scsi0
cicustom: user=local:snippets/custom-cloudinit.yaml
ide2: local-lvm:vm-9000-cloudinit,media=cdrom
ipconfig0: ip=dhcp
memory: 1024
meta: creation-qemu=9.2.0,ctime=1774872190
name: ubuntu-template
net0: virtio=BC:24:11:E7:00:7A,bridge=vmbr0
onboot: 1
scsi0: local-lvm:base-9000-disk-0,size=2252M
scsihw: virtio-scsi-pci
serial0: socket
smbios1: uuid=58f92c4e-b87d-45dc-8084-81498366e030
template: 1
vga: serial0
vmgenid: e9bdd442-509c-4fed-90cf-eefb8888dab9
```

## Install Terraform on host
#### Install dependencies:
```bash
sudo apt update && sudo apt install -y gnupg software-properties-common curl
```
#### Add HashiCorp GPG key:
```bash
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
```
#### Add official HashiCorp repo
```bash
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
```
#### Update and install package
```bash
sudo apt update && sudo apt install terraform
```
## Install Ansible on host
#### Add official ansible ppa
```bash
sudo add-apt-repository --yes --update ppa:ansible/ansible
```
#### Install ansible
```bash
sudo apt install ansible -y
```
## Change dir (CD) to terraform folder 
#### First, terraform init
```bash
root@Control-Node:/home/admin/terraform-setup-overview/terraform-vbox-cluster# terraform init
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/local...
- Finding latest version of hashicorp/null...
- Finding telmate/proxmox versions matching "3.0.2-rc06"...
- Finding latest version of hashicorp/time...
- Installing hashicorp/local v2.7.0...
- Installed hashicorp/local v2.7.0 (signed by HashiCorp)
- Installing hashicorp/null v3.2.4...
- Installed hashicorp/null v3.2.4 (signed by HashiCorp)
- Installing telmate/proxmox v3.0.2-rc06...
- Installed telmate/proxmox v3.0.2-rc06 (self-signed, key ID A9EBBE091B35AFCE)
- Installing hashicorp/time v0.13.1...
- Installed hashicorp/time v0.13.1 (signed by HashiCorp)
Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://developer.hashicorp.com/terraform/cli/plugins/signing
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```
#### Check syntax code with terraform validate
```bash
root@Control-Node:/home/admin/terraform-setup-overview/terraform-vbox-cluster# terraform validate
Success! The configuration is valid.
```
#### If no error, check resource with terraform plan
```bash
#Check resource again
terraform plan
symbols:
  + create

Terraform will perform the following actions:

  # local_file.ansible_inventory will be created
  + resource "local_file" "ansible_inventory" {
      + content              = <<-EOT
            [masters]
            master-cp1 ansible_host=10.10.0.199

            [workers]
            worker-node1 ansible_host=10.10.0.101
            worker-node2 ansible_host=10.10.0.102
            worker-node3 ansible_host=10.10.0.103


            [all:vars]
            ansible_user=ubuntu
            ansible_ssh_private_key_file=~/.ssh/id_rsa
        EOT
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "./k8s-ansible/inventory/hosts.ini"
      + id                   = (known after apply)
    }
....
Plan: 9 to add, 0 to change, 0 to destroy.
```
#### Final, execure terraform apply
```bash
terraform apply -parallelism=1
```
<img width="2558" height="1394" alt="image" src="https://github.com/user-attachments/assets/477e656b-c12c-42b0-ba06-e317d9c3f3d5" />

