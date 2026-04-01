# The setup consists of 1 master and 2 workers with the following IP configuration:
```bash
Master-CP1 192.168.1.199	# "Leader" role
Master-CP2 192.168.1.99		# Assume it already exists as "Follower" role
Master-CP3 192.168.1.98		# Assume it already exists as "Follower" role
Worker-Node1 192.168.1.101
Worker-Node2 192.168.1.102
Jenkins-Server 192.168.1.200
```

## Assume i have already installed and configured ssh-key that allow ssh from installation-server to the nodes

I've created a username 'admin' on all Worker and Master nodes as a controller user, allowing the use of Ansible (if needed).

```bash
ssh-copy-id admin@192.168.1.XX
```
## Perform theses commands on both Master and Worker nodes:

#### Enable kernel modules
```bash
cat <<EOF |sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
```
#### Edit Sysctl network settings
```bash
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl --system
```
#### Install Container Runtime
```bash
sudo apt install containerd -y
```
#### Generate default config and edit SystemdCgroup = true
```bash
sudo containerd config default | sudo tee /etc/containerd/config.toml

SystemdCgroup = true
```
#### Install dependecies package
```bash
sudo apt install -y apt-transport-https ca-certificates curl gpg
```
#### Add Kubernetes repository and install kubeadm, kubectl, kubelet

Add key:
```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key   | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
```
Add repo:
```bash
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```
Update, install and hold version:
```bash
sudo apt update

sudo apt install -y kubelet kubeadm kubectl -y

sudo apt-mark hold kubelet kubeadm kubectl containerd
```
## Perform these commands on Master nodes:
#### Generate cluster k8s with kubeadm init
```bash
 kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=192.168.1.199
```
#### Configure account on the Control-Plan node to have admin access to the API server from non-priviledge account 
```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/Kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```
####  Install Calico CNI
```bash
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml
```
#### Get join command from Master Node
```bash
kubeadm token create --print-join-command
```
## Perform these commands on Worker nodes to join K8s cluster:

```bash
kubeadm join k8s-api.lab.local:6443 --token 9n4qda.2y2supcehmdmi1k9 --discovery-token-ca-cert-hash sha256:b2be7c68c4e5d5688765c562443274442fd769d7573578d6fc89fccf656730b5
```
