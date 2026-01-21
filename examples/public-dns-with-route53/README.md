# W&B Fresh Deployment with Route53 DNS Management

## Overview

This template provides a **complete, end-to-end deployment** of Weights & Biases (W&B) on AWS with full infrastructure automation. It's designed for fresh deployments where AWS manages everything including DNS zone creation and application deployment.

## What This Template Does

This Terraform configuration automatically creates:

### AWS Infrastructure (`wandb_infra` module)
- **Networking**: VPC with public/private subnets across multiple AZs
- **DNS**: Route53 hosted zone for your domain (newly created)
- **Compute**: EKS cluster with managed node groups
- **Database**: Aurora MySQL (RDS) cluster with Multi-AZ deployment
- **Caching**: ElastiCache Redis cluster
- **Storage**: S3 bucket for artifacts and files
- **Queueing**: SQS queue for S3 event notifications
- **Security**: KMS keys, IAM roles, security groups
- **SSL/TLS**: ACM certificate for HTTPS
- **Load Balancing**: Application Load Balancer (ALB)

### W&B Application (`wandb_app` module)
- Deploys W&B application to Kubernetes using Helm
- Configures all connections to AWS resources
- Sets up ingress for public access
- Integrates with S3, MySQL, Redis, SQS, and KMS

## Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with appropriate permissions
2. **W&B License Key** - Obtain from [deploy.wandb.ai](https://deploy.wandb.ai)
3. **Domain Name** - You can use a new domain or subdomain
4. **Terraform** >= 1.9 installed
5. **AWS CLI** configured with credentials
6. **kubectl** installed (optional, for cluster management)

## Deployment Steps

### 1. Configure Variables

Create a `terraform.tfvars` file with your configuration:

```hcl
# Required Variables
namespace  = "wandb-prod"              # Prefix for all AWS resources
domain     = "wandb.example.com"       # Your domain name
subdomain  = null                      # Optional: subdomain (e.g., "app" for app.wandb.example.com)
license    = "your-license-key-here"   # Get from https://deploy.wandb.ai
aws_region = "us-west-2"               # Your preferred AWS region

# EKS Configuration (Optional - defaults provided)
eks_cluster_version = "1.30"

# Network Access Control (Optional - defaults to public)
allowed_inbound_cidr      = ["0.0.0.0/0"]  # Restrict to specific IPs if needed
allowed_inbound_ipv6_cidr = ["::/0"]       # IPv6 access
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review the Deployment Plan

```bash
terraform plan
```

Review the resources that will be created. This typically includes:
- 1 Route53 hosted zone
- 1 VPC with subnets, NAT gateways, internet gateway
- 1 EKS cluster with node groups
- 1 RDS Aurora MySQL cluster
- 1 ElastiCache Redis cluster
- 1 S3 bucket + SQS queue
- 1 ACM certificate
- 1 Application Load Balancer
- Multiple security groups, IAM roles, and KMS keys
- W&B Kubernetes deployment (Helm chart)

### 4. Deploy

```bash
terraform apply
```

Type `yes` when prompted. Deployment typically takes 20-30 minutes.

### 5. Configure DNS

After deployment, Terraform will output Route53 nameservers:

```bash
terraform output route53_nameservers
```

**Update your domain registrar** to use these nameservers:
- If using `wandb.example.com`: Update `example.com` NS records to point to the Route53 nameservers
- If using a new domain: Update your domain registrar's nameserver settings

DNS propagation can take 24-48 hours, but usually completes within a few hours.

### 6. Access W&B

Once DNS propagates, access your W&B instance:

```bash
terraform output url
```

Navigate to this URL in your browser and complete the initial setup.

## Post-Deployment

### View All Outputs

```bash
terraform output
```

### Access EKS Cluster

```bash
aws eks update-kubeconfig --name $(terraform output -raw cluster_name) --region $(terraform output -raw aws_region)
kubectl get pods -A
```

### View W&B Logs

```bash
kubectl logs -n default -l app=wandb --tail=100 -f
```

## Configuration Options

### Public vs Private Access

This template deploys W&B with **public access**. To restrict access:

1. Modify `allowed_inbound_cidr` in `terraform.tfvars`:
   ```hcl
   allowed_inbound_cidr = ["10.0.0.0/8", "your-office-ip/32"]
   ```

2. Set `kubernetes_public_access_cidrs` in `main.tf` for EKS API access restrictions

### Deployment Size

The infrastructure module supports deployment sizing. To customize, add to `main.tf`:

```hcl
module "wandb_infra" {
  # ... existing config ...

  size = "medium"  # Options: small, medium, large, xlarge, xxlarge
}
```

## Architecture

```
                                 Internet
                                    |
                           [Route53 DNS Zone]
                                    |
                        [ACM Certificate (SSL/TLS)]
                                    |
                    [Application Load Balancer (ALB)]
                                    |
                    +---------------+---------------+
                    |                               |
              [EKS Cluster]                   [S3 Bucket]
                    |                               |
        +-----------+-----------+            [SQS Queue]
        |           |           |
    [W&B Pods] [W&B Pods] [W&B Pods]
        |
        +------------------+------------------+
        |                  |                  |
   [RDS Aurora]      [ElastiCache]      [KMS Keys]
     (MySQL)           (Redis)
```

## Troubleshooting

### Deployment Failures

1. **ACM Certificate timeout**: Certificate validation can take up to 2 hours. Be patient or pre-create the certificate.
2. **EKS cluster timeout**: Ensure your AWS account has sufficient service quotas for EC2, VPC, and EKS.
3. **Insufficient permissions**: Verify your AWS credentials have the required permissions.

### DNS Not Resolving

1. Verify nameservers are correctly configured at your domain registrar
2. Check DNS propagation: `dig +short NS wandb.example.com`
3. Wait 24-48 hours for full DNS propagation

### W&B Application Issues

1. Check pod status: `kubectl get pods`
2. View logs: `kubectl logs -l app=wandb --tail=100`
3. Verify database connectivity: `kubectl exec -it <wandb-pod> -- mysql -h <db-endpoint>`

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will delete all data including the database and S3 bucket. Ensure you have backups before destroying.

## Support

- **W&B Documentation**: [docs.wandb.ai](https://docs.wandb.ai)
- **Terraform Module Issues**: [GitHub Issues](https://github.com/wandb/terraform-aws-wandb/issues)
- **W&B Support**: Contact your Customer Success Manager

## License

This module requires a valid W&B Enterprise license. Contact [deploy@wandb.com](mailto:deploy@wandb.com) for licensing information.
