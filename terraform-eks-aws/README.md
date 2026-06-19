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

## Review resouce created 

### image here


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

