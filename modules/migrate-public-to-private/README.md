# Migrate from public to private dns

For users who have setup an AWS External DNS WandB stack and want to migrate it to a private stack (which is only accessible inside AWS network).

This module will create new resources only and will not touch any of the current external stack resources, so this will be a plug and play solution that introduces no drift in current terraform.

If users need to migrate to private they can just add this module. If they want to revert to original public setting, simply remove this module.

Below is a list of resources that will be created for private access:

- NLB in private subnet
- Security group for NLB
- Target Group and Listener
    - K8s ALB will be the target
- Route53 DNS record in private hosted zone
    - Record points towards NLB.

## Prerequisites

Below are the prerequisites for the migration:

- AWS external dns setup ready
- User has a private network setup in AWS (for eg: OpenVpn)
- User has a Private hosted zone setup in AWS

## Steps to deploy this module

This module is referenced in the [main.tf](./main.tf) file. With default values, it will not create any resources.

NOTE: *Assuming the terraform.tfstate file already exists in this directory and the external dns setup is ready, you can follow the below steps to deploy this module.*

1. For deploying this module, you need to set the following variables in the `auto.tfvars` file:

    ```terraform
    # old values from external dns setup
    namespace   = "wandb"
    domain_name = "mywandb.io"
    subdomain   = "test"
    zone_id     = "Zxxxxxxxxxxx"
    wandb_license = "xxxx"

    # new values for private dns setup
    migrate_public_to_private           = true
    private_hosted_zone_id              = "Zxxxx"
    private_dns_network_id              = "vpc-xxx"
    private_dns_network_cidr_block      = "10.x.x.x/16"
    private_dns_network_private_subnets = ["subnet-xxxx", "subnet-xxxx"]
    ```

2. Apply the changes:

    ```bash
    terraform init
    terraform plan -var-file=auto.tfvars
    terraform apply -var-file=auto.tfvars
    ```


## Steps to remove this module

1. Set the `migrate_public_to_private` variable to `false` in the `auto.tfvars` file.
2. Run terraform to remove the module.
    ```bash
    terraform plan -var-file=auto.tfvars
    terraform apply -var-file=auto.tfvars
    ```
