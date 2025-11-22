# Terraform Infrastructure

This directory contains the Terraform configurations for the cloud-devops-demo project.

## Structure

```
terraform/
├── modules/
│   └── vpc/              # Shared VPC module
├── jenkins/              # Jenkins CI/CD server
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── user_data.sh      # Jenkins initialization script
│   └── plugins.txt       # Jenkins plugins list
└── eks/                  # Kubernetes cluster
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

## Deployment Order

### 1. Deploy Jenkins first

```bash
cd jenkins

# Generate SSH key
ssh-keygen -t rsa -b 4096 -f id_rsa -N ""

# Create terraform.tfvars
cat > terraform.tfvars << EOF
jenkins_admin_password   = "your-password"
docker_registry_user     = "your-dockerhub-username"
docker_registry_password = "your-dockerhub-token"
EOF

# Deploy
terraform init
terraform apply
```

### 2. Deploy EKS (uses same VPC as Jenkins)

```bash
cd ../eks

# Create terraform.tfvars with VPC ID from Jenkins output
cat > terraform.tfvars << EOF
vpc_id = "vpc-xxxxxxxxx"  # Get from Jenkins outputs
EOF

# Deploy
terraform init
terraform apply
```

### 3. Configure kubectl

```bash
aws eks update-kubeconfig --region eu-north-1 --name cloud-devops-eks
kubectl get nodes
```

### 4. Deploy application

```bash
kubectl apply -f ../../../k8s/
```

## Cleanup

Destroy in reverse order:

```bash
# First EKS
cd eks && terraform destroy

# Then Jenkins
cd ../jenkins && terraform destroy
```
