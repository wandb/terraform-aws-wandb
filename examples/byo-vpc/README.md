# Deploy W&B required infrastructure to an existing VPC

## About

This example is a minimal example of what is needed to deploy an instance of
Weights & Biases that uses an external DNS into an already existing VPC.

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
- An existing VPC with public and/or private subnets.
- Valid W&B Local license (You get one at [here](https://deploy.wandb.ai))

## A sample Terraform Variables Example looks like:

Create a `terraform.tfvars` file in this directory before running this example

```ini
namespace     = ""
domain_name   = ""
zone_id       = "Z0322..."
subdomain     = ""
wandb_license = ""
wandb_version = "0.49.0"

#allowed_inbound_cidr = [
#  "0.0.0.0/0",
#  "192.168.0.0/16"
#]

#disable ipv6
#allowed_inbound_ipv6_cidr = ["::/1"]

enable_dummy_dns = false
enable_operator_alb = false

eks_cluster_version = "1.25"

vpc_id = "vpc-0a..."
vpc_cidr = "10.x.x.x/x"

network_private_subnets = [ "subnet-03...", "subnet-08..." ]
network_private_subnet_cidrs = ["10.x.x.x/x", "10.x.x.x/x"]

network_public_subnets = []
network_public_subnet_cidrs = []

network_database_subnets = [ "subnet-06...", "subnet-02..." ]
network_database_subnet_cidrs = ["10.x.x.x/x", "10.x.x.x/x"]

network_elasticache_subnets = [ "subnet-05...", "subnet-0e..." ]
# network_elasticache_subnet_cidrs = ["10.x.x.x/x", "10.x.x.x/x"]
```
