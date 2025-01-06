# README for Private Access Only Example

## Overview

This example demonstrates how to set up a private access-only configuration for Weights & Biases (W&B) using Terraform on AWS. This configuration ensures that W&B services are accessible only within a specified Virtual Private Cloud (VPC), enhancing security by preventing public internet access.

## Prerequisites

Before you begin, ensure you have the following:

- **AWS Account**: An active AWS account is required.
- **Terraform**: Install Terraform on your local machine. You can download it from [Terraform's official website](https://www.terraform.io/downloads.html).
- **AWS CLI**: Install and configure the AWS CLI with appropriate permissions to create resources in your account.

## Getting Started

### Clone the Repository

Clone the repository to your local machine:

```bash
git clone https://github.com/wandb/terraform-aws-wandb.git
cd terraform-aws-wandb/examples/private-access-only
```

### Configuration

1. **Modify Variables**: Open the `variables.tf` file and adjust the variables according to your requirements, such as VPC ID, subnet IDs, and region.

2. **Create a Terraform Variables File**: Create a `terraform.tfvars` file to specify values for the variables defined in `variables.tf`. For example:

   ```hcl
   namespace   = "your-namespace"
   allowed_inbound_cidr = "inbound cidr"
   vpc_id = "your-vpc-id"
   subnet_ids = ["subnet-xxxxxx", "subnet-yyyyyy"]
   region = "us-west-2"
   ```

### Initialize Terraform

Run the following command to initialize Terraform. This command downloads the necessary provider plugins:

```bash
terraform init
```

### Plan the Deployment

Before applying changes, it's a good practice to see what will be created:

```bash
terraform plan
```

### Apply the Configuration

To create the resources defined in your Terraform configuration, run:

```bash
terraform apply
```

You will be prompted to confirm before proceeding. Type `yes` to continue.

### Accessing W&B

After deployment, you will have a private access-only setup for W&B. Ensure that any services or applications that need to access W&B are running within the same VPC or have appropriate connectivity (e.g., VPN).

## Cleanup

To remove all resources created by this example, run:

```bash
terraform destroy
```

You will again be prompted to confirm. Type `yes` to proceed with resource deletion.

## Additional Resources

- [Terraform Documentation](https://www.terraform.io/docs/index.html)
- [Weights & Biases Documentation](https://docs.wandb.ai/)
- [AWS Documentation](https://docs.aws.amazon.com/)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/wandb/terraform-aws-wandb/blob/main/LICENSE) file for details.

---

This README provides a concise guide for users looking to deploy a private access-only W&B setup using Terraform on AWS. Adjust any sections as necessary based on specific configurations or additional instructions relevant to your use case.

Citations:
[1] https://github.com/wandb/terraform-aws-wandb/tree/main/examples/private-access-only