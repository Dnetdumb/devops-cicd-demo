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
Reference source:
https://www.proxmox.com/en/downloads (Proxmox)
https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img (qcow2 format)
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
    ubuntu:123456
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
terraform init
```
#### Check syntax code with terraform validate
```bash
terraform validate
```
#### If no error, check resource and then apply
```bash
#Check resource again
terraform plan

#Apply config and setup
terraform apply 
```
