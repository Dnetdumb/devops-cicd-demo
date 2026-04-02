[masters]
master-cp1 ansible_host=${master_ip}

[workers]
%{ for i, ip in worker_ip ~}
worker-node${i + 1} ansible_host=${ip}
%{ endfor }

[all:vars]
ansible_user=${ssh_user}
ansible_ssh_private_key_file=~/.ssh/id_rsa

