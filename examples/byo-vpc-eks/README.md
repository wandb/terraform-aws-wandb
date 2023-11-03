# Deploy W&B required infrastructure to an existing VPC and existing EKS

## About

This example is a minimal example of what is needed to deploy an instance of 
Weights & Biases that uses an external DNS into an already existing VPC and EKS cluster.

## Module Prerequites

As with the main version of this module, this example assumes the following
resources already exist:

- Valid subdomain that uses Amazon Route 53 as the Dns services ([Learn more
  here](<(https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingNewSubdomain.html)>)
  1. Create a Route53 zone for `<subdomain>.<domain_name>`. When you want to use
     Amazon Route 53 as the DNS service for a new subdomain without migrating
     the parent domain, you start by creating a hosted zone for the subdomain.
  2. Create a Namespace Record (NS) in your external DNS provide that points to
     this Route53 zone. Update the DNS service for the parent domain by adding
     NS records for the subdomain. This is known as delegating responsibility
     for the subdomain to Route 53. For example, if the parent domain
     example.com is hosted with another DNS service and you created the
     subdomain test.example.com in Route 53, you must update the DNS service for
     example.com with new NS records for test.example.com.
- An existing VPC with public and private subnets.
- An existing EKS cluster with a node group.
- Valid W&B Local license (You get one at [here](https://deploy.wandb.ai))

## A sample Terraform Variables Example looks like:
Create a `terraform.tfvars` file in this directory before running this example
```
namespace                        = ""
domain_name                      = ""
zone_id                          = "Z01XXXXXXXXXXXXXX"
wandb_license                    = "<license_key>"
network_id                       = "vpc-xxxxxxxxxxxx"
network_private_subnets          = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb", "subnet-ccccccccccccccccc"]
network_public_subnets           = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb", "subnet-ccccccccccccccccc"]
network_database_subnets         = ["subnet-aaaaaaaaaaaaaaaaa", "subnet-bbbbbbbbbbbbbbbbb", "subnet-ccccccccccccccccc"]
network_cidr                     = "x.x.x.x/x"
network_private_subnet_cidrs     = ["x.x.x.x/x", "x.x.x.x/x", "x.x.x.x/x"]
network_public_subnet_cidrs      = ["x.x.x.x/x", "x.x.x.x/x", "x.x.x.x/x"]
network_database_subnet_cidrs    = ["x.x.x.x/x", "x.x.x.x/x", "x.x.x.x/x"]
eks_cluster_version              = "1.25"
```
