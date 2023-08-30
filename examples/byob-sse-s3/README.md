# BYOB

## About

This example does not deploy an instance of Weights & Biases. Instead it is an
example of the resources that need to be created to deploy use with an S3 bucket
for.

This module uses AE256 Encryption to protect the object store.

---

When using bring your own bucket you will need to grant our account
(`830241207209`) access to an S3 Bucket and KMS Key for encryption and decryption.
decryption

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

### SSE-S3 encryption

Amazon S3 now applies server-side encryption with Amazon S3 managed keys (SSE-S3)
as the base level of encryption for every bucket in Amazon S3. Starting January 5, 2023,
all new object uploads to Amazon S3 are automatically encrypted at no additional cost
and with no impact on performance. The automatic encryption status for S3 bucket default
encryption configuration and for new object uploads is available in AWS CloudTrail logs,
S3 Inventory, S3 Storage Lens, the Amazon S3 console, and as an additional Amazon S3 API
response header in the AWS Command Line Interface and AWS SDKs. For more information, see
[Default encryption FAQ](https://docs.aws.amazon.com/AmazonS3/latest/userguide/default-encryption-faq.html).

Do not configure a KMS key on the object store. Your configuration should look like this.

![sse-s3-default](./sse-s3.png)

### Creating S3 Bucket

Lastly, you'll need to create the S3 bucket. Make sure to enable CORS access. Your CORS configuration should look like the following:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CORSConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
<CORSRule>
    <AllowedOrigin>*</AllowedOrigin>
    <AllowedMethod>GET</AllowedMethod>
    <AllowedMethod>HEAD</AllowedMethod>
    <AllowedMethod>PUT</AllowedMethod>
    <AllowedHeader>*</AllowedHeader>
    <ExposeHeader>ETag</ExposeHeader>
    <MaxAgeSeconds>3000</MaxAgeSeconds>
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
      "Action": [
        "s3:GetObject*",
        "s3:GetEncryptionConfiguration",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:ListBucketVersions",
        "s3:AbortMultipartUpload",
        "s3:DeleteObject",
        "s3:PutObject",
        "s3:GetBucketCORS",
        "s3:GetBucketLocation",
        "s3:GetBucketVersioning"
      ],
      "Resource": [
        "arn:aws:s3:::<WANDB_BUCKET>",
        "arn:aws:s3:::<WANDB_BUCKET>/*"
      ]
    }
  ]
}
```
