# Deploy a W&B with a subdomain that uses Amazon Route 53 as the DNS service

## About

This exmaple is a minimal example of what is needed to deploy an instance of
Weights & Biases that uses an external DNS.

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
- Valid W&B Local license (You get one at [here](https://deploy.wandb.ai))

## Terraform Variables Example

```
namespace   = "wandb"
subdomain   = "test"
domain_name = "wandb.io"
license     = "<license key>"
```

This will deploy an instance at `test.wandb.io`.

## Migrate from public to private dns stack

To migrate from a public DNS to a private DNS, follow the instructions in [migrate.md](./migrate.md).
