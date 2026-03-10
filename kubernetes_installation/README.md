# Mô hình cài đặt gồm 1 master và 2 worker có cấu hình IP như sau:

Master-CP1 192.168.1.199
Master-CP2 192.168.1.99 
Master-CP3 192.168.1.98
Worker-Node1 192.168.1.101
Worker-Node2 192.168.1.102
Jenkins-Server 192.168.1.200

Note: Trong 1 cluster Kubernetes nên HA (High Availability) Master lẻ để cơ chế bầu chọn Leader và Follower diễn ra dễ dàng và tối ưu nhất

## Giả định là đã cấu hình ssh-key cho phép SSH từ installation-server tới các node

Ở đây mình tạo user 'admin' trên tất cả các Worker và Master node như một user controller cho phép sử dụng ansible (nếu cần thiết)

ssh-copy-id admin@192.168.1.XX

## Các bước thực hiện trên Master và Worker nodes:

### Enable kernel modules

cat <<EOF |sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

### Edit Sysctl network settings

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system

### Cài Container Runtime

sudo apt install containerd -y

#### Generate default config và edit SystemdCgroup = true

sudo containerd config default | sudo tee /etc/containerd/config.toml

SystemdCgroup = true

### Install các dependecies package

sudo apt install -y apt-transport-https ca-certificates curl gpg

### Add Kubernetes repository and install kubeadm, kubectl, kubelet

Add key:

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key   | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

Add repo:

echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

Update, install and hold version:

sudo apt update

sudo apt install -y kubelet kubeadm kubectl -y

sudo apt-mark hold kubelet kubeadm kubectl containerd

## Thực hiện trên Master Node:

### Cài đặt Calico

