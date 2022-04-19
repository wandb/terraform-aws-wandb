# BYOB

## About

This example does not deploy an instance of Weights & Biases. Instead it is an
example of the resources that need to be created to deploy use with an S3 bucket
for.

---

When using bring your own bucket you will need to grant our account
(`830241207209`) access to an S3 Bucket and KMS Key for encryption and description.

## Using Terraform

Terraform is the preferred method for deploying BYOB.

Infrastructure as code (IaC) tools allow you to manage infrastructure with
configuration files rather than through a graphical user interface. IaC
allows you to build, change, and manage your infrastructure in a safe,
consistent, and repeatable way by defining resource configurations that you
can version, reuse, and share.

1. Please follow the instructions for install [Terraform
   1.0+](https://learn.hashicorp.com/tutorials/terraform/install-cli)
2. Authenticated with Terraform with AWS. You can do this in many ways learn
   more
   [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration).
   It is most common to install and authenticate with [AWS
   CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html).
3. Pull terraform-aws-wandb repo and cd to this
   [directory](https://github.com/wandb/terraform-aws-wandb/tree/main/examples/byob)
4. Run `terraform init`
5. Run `terraform apply`. If you need to assume a different role, please
   configure that in the `main.tf` file before running `apply`. You can learn
   more
   [here](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#assuming-an-iam-role).
6. Please provide the resulting output to Weights & Biases (bucket name and kms arn)

## Using AWS Console

### Creating KMS Key

We require you to provision a KMS Key which will be used to encrypt and decrypt
your S3 bucket. Make sure to enable key usage type for `ENCRYPT_DECRYPT`
purposes. It will require to have the following policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Internal",
      "Effect": "Allow",
      "Principal": { "AWS": "<you account id>" },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "External",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::830241207209:root" },
      "Action": "kms:*",
      "Resource": "*"
    }
  ]
}
```

This policy gives access to your internal account, a swell while also providing
our service account with the requires permissions. Please keep a record of the
KMS ARN as we will need that during the deployment.

### Creating S3 Bucket

Lastly, you'll need to create the S3 bucket. Make sure to enable CORS access. Your CORS configuration should look like the following:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
<CORSRule>
    <AllowedOrigin>*</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>PUT</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
</CORSRule>
</CORSConfiguration>
```

Also, enable server side encryption and use the KMS key you just generated.

Finally, grant the Weights & Biases Deployment account access to this S3 bucket:

```json
{
  "Version": "2012-10-17",
  "Id": "WandBAccess",
  "Statement": [
    {
      "Sid": "WAndBAccountAccess",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::830241207209:root" },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::<WANDB_BUCKET>",
        "arn:aws:s3:::<WANDB_BUCKET>/*"
      ]
    }
  ]
}
```
