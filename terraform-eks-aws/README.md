# Folder Structure

```bash
terraform-eks-aws/
├── main.tf             # Gọi các module chính
├── variables.tf        # Biến toàn cục
├── providers.tf        # Cấu hình AWS provider
├── outputs.tf          # Output thông tin cluster
└── modules/
    ├── vpc/            # Tạo VPC, Subnets (2 AZs)
    └── eks/            # Khởi tạo EKS Cluster & Node Groups
```

## Install AWS CLI
```bash
sudo apt update
sudo apt install -y awscli

# Check version:
/usr/local/bin/aws --version
aws-cli/2.35.7 Python/3.14.5 Linux/5.15.0-179-generic exe/x86_64.ubuntu.22

```

## Config AWS Credentials
```bash
aws configure --profile terraform-operator

AWS Access Key ID     → <YOUR_AWS_ACC_ACCESS_KEY_ID>
AWS Secret Access Key → <YOUR_AWS_ACC_SECRET_KEY>
Default region        → ap-southeast-1
Default output        → json

# Check:
aws sts get-caller-identity --profile terraform-operator
{
    "UserId": "AIDARK5M7OCX...",
    "Account": "09216...",
    "Arn": "arn:aws:iam::0921676...:user/terraform-operator"
}

```
## Create EKS cluster with Terraform
```bash
terraform init
terraform plan > terraform-plan.output
terraform apply
```
<img width="1275" height="1009" alt="EKS-1" src="https://github.com/user-attachments/assets/2bec698d-472f-48f4-832e-47bca73721ac" />

<img width="1275" height="656" alt="EKS-2" src="https://github.com/user-attachments/assets/3a468f34-f156-4c0c-9759-8db8824df89a" />


## Review resouce created 

<img width="1269" height="784" alt="EKS-3" src="https://github.com/user-attachments/assets/385b386e-2100-4055-8d75-61b1adb4a861" />

### VPC

<img width="1274" height="421" alt="EKS-4" src="https://github.com/user-attachments/assets/a3b7a5d0-7a6c-4021-81a0-fb3fe752feec" />

### Subnets

<img width="1272" height="443" alt="EKS-5" src="https://github.com/user-attachments/assets/1f5f2166-7b1d-4c8f-9695-516c83ecfb97" />

### Route tables, igw and NAT gateway

<img width="1274" height="421" alt="EKS-6" src="https://github.com/user-attachments/assets/464feb44-d79b-4195-a181-4a2ff4c736f9" />

<img width="1278" height="383" alt="EKS-7" src="https://github.com/user-attachments/assets/7f38391c-87cf-4959-a78d-daca0ff3cb6e" />

<img width="1275" height="284" alt="EKS-8" src="https://github.com/user-attachments/assets/38e237a9-72ae-4c72-becb-8aae223f4c0b" />

### Security group for "prod-cluster"

<img width="1264" height="834" alt="EKS-9" src="https://github.com/user-attachments/assets/eb6cc61b-7fea-499c-af60-4a07aa7102cb" />


## Switch multi cluster with "kubectx"
```bash
root@Master-CP1:/home/admin# kubectx
arn:aws:eks:ap-southeast-1:092167696558:cluster/prod-cluster
kubernetes-admin@kubernetes

#Switch to prod-cluster:
root@Master-CP1:/home/admin# kubectx arn:aws:eks:ap-southeast-1:092167696558:cluster/prod-cluster
✔ Switched to context "arn:aws:eks:ap-southeast-1:092167696558:cluster/prod-cluster".

```

## Check cluster
```bash
root@Master-CP1:/home/admin# kubectl get nodes -owide
NAME                                            STATUS   ROLES    AGE   VERSION                INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                        KERNEL-VERSION                    CONTAINER-RUNTIME
ip-10-0-1-237.ap-southeast-1.compute.internal   Ready    <none>   85m   v1.31.14-eks-0de9cde   10.0.1.237    <none>        Amazon Linux 2023.12.20260608   6.1.174-217.345.amzn2023.x86_64   containerd://2.2.4+unknown
ip-10-0-2-26.ap-southeast-1.compute.internal    Ready    <none>   85m   v1.31.14-eks-0de9cde   10.0.2.26     <none>        Amazon Linux 2023.12.20260608   6.1.174-217.345.amzn2023.x86_64   containerd://2.2.4+unknown

kubectl get pods -A
NAMESPACE     NAME                       READY   STATUS    RESTARTS   AGE
kube-system   aws-node-lxvv8             2/2     Running   0          89m
kube-system   aws-node-rkftw             2/2     Running   0          89m
kube-system   coredns-7f5d9b76bf-92hvm   1/1     Running   0          92m
kube-system   coredns-7f5d9b76bf-n6krc   1/1     Running   0          92m
kube-system   kube-proxy-q6d5c           1/1     Running   0          89m
kube-system   kube-proxy-znqdf           1/1     Running   0          89m
```

