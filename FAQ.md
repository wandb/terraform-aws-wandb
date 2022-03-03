# Weights & Biases AWS Module FAQs

#### Are all W&B services hosted within a single region in AWS?

> Yes, all services need to be hosted in a single region of customer's choice within AWS

#### How long typically would it take to spin up all the required resources?

> It typically takes approximately 30 mins to spin up all the required resources in AWS

#### What regions in AWS does W&B support?

> W&B supports all the regions listed here and supported by Amazon's EKS: https://docs.aws.amazon.com/general/latest/gr/eks.html

#### Does the user running this terraform need specialized knowledge of AWS services?

> Typically, to run terraform the user must know to configure awscli with the right credentials and run `terraform apply`. It is recommended
> to have a certain level of knowledge on [these list of resources](https://github.com/wandb/terraform-aws-wandb/tree/venky/add-faq-section#aws-services-used) to be able to deploy and maintain W&B successfully.

#### How does the W&B private cloud architecture look like?

> The W&B private cloud architecture can be found here:
> https://lucid.app/publicSegments/view/bad4a232-2b25-44ed-b9c1-baf8aab0e115

#### What are the different subnets created as part of the W&B deployment?

> The W&B AWS terraform spins up atleast two subnets, one per availability zone in a region to account for fail over. If the deployment is private, then W&B creates two public subnets and two private subnets.

#### What permissions should be granted to the W&B deployment?

> The following permissions are required for the W&B deployment to AWS resources,

```
"ec2:*",
"eks:*",
"s3:*",
"kms:*",
"autoscaling:*",
"iam:*",
"logs:*",
"sqs:*",
"acm:*",
"rds:*",
"route53:*",
"route53resolver:*",
"elasticloadbalancing:*"
```

#### How are default keys encrypted?

```
By default keys to encrypt data are stored using KMS. Keys are automatically rotated by AWS every year.

NOTE: From AWS documentation, automatic key rotation has no effect on the data that the KMS key protects. It does not rotate the data keys that the KMS key generated or re-encrypt any data protected by the KMS key, and it will not mitigate the effect of a compromised data key.

If you need any of the following, you must provide your own KMS key:

- Control over the rotation schedule
- Control over the strength of the key
- Rotate the key material itself

You can supply your own KMS key to our terraform module via the **kms_key_alias** variable:

[https://registry.terraform.io/modules/wandb/wandb/aws/latest?tab=inputs](https://registry.terraform.io/modules/wandb/wandb/aws/latest?tab=inputs)"
```

#### How are credentials managed?

> Credentials/Secrets are stored in the terraform state file. Once terraform apply completes successfully it is important to save the terraform.tfstate file to be able to maintain the stable state of the deployment.

#### How is the sensitive data like artifacts stored?

> Customer sensitive data is stored in an S3 bucket. Once authenticated a user can access S3 bucket resource through pre-signed urls. The user must have access to the project to view these resources.

#### What are the different data encrytion configurations in place?

```
- S3 bucket is encrypted by a customer defined KMS key
- Aurora MySQL Database is encrypted by a customer defined KMS key**
- A deployment option is available to use an internal queue which lets the python client inform the Weights & Biases when a file is uploaded (this removes the need for SQS, which is not encrypted).
- Other private variables such as credentials are stored in the Terraform which is encrypted and isolated from each deployment.
```

#### What are the billable services that are spun up as part of the deployment?

> Most resources listed here are billable by AWS. To effectively calculate the pricing based on usage, [aws calculator](https://calculator.aws/) could be a good resource.

#### Does the database & S3 storage need to be backed up?

**Database backup**

> When spinning up Aurora MySQL databases, it is strongly recommended the customers setup automated database snapshotting to take place at a regular interval and also enable deletion protection. Unless the customer wants to migrate W&B services from one AWS instance to another it is recommended but not required to perform a backup.

**S3 backup**

> Similar to the database, backing up S3 or having a replica S3 with automated syncing is recommended but not required.

#### How does W&B rotate/maintain credentials & keys?

**Rotating MySQL Database Credentials**

```
1. Create a new user in the MySQL database
   1. Login as an existing user that has privileges to create new users and run the following SQL statements:

- CREATE USER <new_username> IDENTIFIED BY <new_password>
- SHOW GRANTS FOR <old_username>
  - For each grant, run:
    - ALTER USER <username> REQUIRE <grant>
- Convert TLS Options for user:
  - SELECT ssl_type, ssl_cipher, x509_issuer, x509_subject FROM mysql.user WHERE User = <old_username>
  - ALTER USER REQUIRE <NONE|SSL|X509>
    - If other replace <NONE|SSL|X509> with:
      - CIPHER <cipher> AND ISSUER <issuer> AND SUBJECT <subject>""
- SET PASSWORD FOR <new_username> = <new_password>

1. Update connection string in terraform via secret
   1. https://github.com/wandb/terraform-kubernetes-wandb#input_mysql_connection_string
2. Restart kubernetes pods
   1. kubectl rollout restart deployment wandb
3. Confirm application working as expected
4. Then delete user
   1. DROP USER <old_username>
```

**Rotate KMS keys**

```
By default keys to encrypt data are stored using KMS. Keys are automatically rotated by AWS every year.

NOTE: From AWS documentation, automatic key rotation has no effect on the data that the KMS key protects. It does not rotate the data keys that the KMS key generated or re-encrypt any data protected by the KMS key, and it will not mitigate the effect of a compromised data key.

If you need any of the following, you must provide your own KMS key:

- Control over the rotation schedule
- Control over the strength of the key
- Rotate the key material itself

You can supply your own KMS key to our terraform module via the `kms_key_alias` variable:

[https://registry.terraform.io/modules/wandb/wandb/aws/latest?tab=inputs](https://registry.terraform.io/modules/wandb/wandb/aws/latest?tab=inputs)

More information about rotating KMS keys can be found here:

[https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html)

And manually rotating keys:[https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-manually](https://docs.aws.amazon.com/kms/latest/developerguide/rotate-keys.html#rotate-keys-manually)"
```

#### Are there any service quotas w.r.t AWS?

> All the default limits specified under the Service Quotas section here: https://docs.aws.amazon.com/general/latest/gr/eks.html would be the default for W&B services as well.
