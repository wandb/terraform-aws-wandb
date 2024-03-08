# Secure Storage Connector Manual 

If you have your own bucket that you would like to integrate with W&B, create the following policy file `bucket-policy.json`. 

```json title="bucket-policy.json"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::${BUCKET_ACCOUNT_ID}:role/${BUCKET_MANAGMENT}" },
      "Action": ["s3:*"],
      "Resource": ["arn:aws:s3:::${BUCKET_NAME}", "arn:aws:s3:::${BUCKET_NAME}/*"]
    },
    {
      "Sid": "WandbAccountAccess",
      "Effect": "Allow",
      "Principal": { "AWS": "arn:aws:iam::725579432336:role/WandbIntegration" },
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
      "Resource": ["arn:aws:s3:::${BUCKET_NAME}", "arn:aws:s3:::${BUCKET_NAME}/*"]
    }
  ]
}
```
Then run the following:

`aws s3api put-bucket-policy --bucket ${BUCKET_NAME} --policy file://bucket-policy.json`

Verify the policy with:

`aws s3api get-bucket-policy --bucket gdi-wandb`

You will also need to add the following cors policy. 

Create the following `cors-policy.json`:

``` json title="cors-policy.json"
{
  "CORSRules": [
    {
      "AllowedOrigins": ["*"],
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "HEAD", "PUT"],
      "MaxAgeSeconds": 3000,
      "ExposeHeaders": ["ETag"]
    }
  ]
}
```

Then run:

`aws s3api put-bucket-cors --bucket ${BUCKET_NAME} --cors-configuration file://cors-policy.json`

To verify:

`aws s3api get-bucket-cors --bucket ${BUCKET_NAME}`
