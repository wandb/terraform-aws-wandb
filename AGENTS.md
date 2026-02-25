# AGENTS.md

## Cursor Cloud specific instructions

### Overview

This is a **Terraform IaC module** (`terraform-aws-wandb`) for provisioning a self-hosted Weights & Biases cluster on AWS. There are no runtime application services to start locally — the "product" is the Terraform module itself.

### Development Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Terraform | ~> 1.9 (installed: 1.9.8) | IaC engine — init, validate, plan |
| tflint | latest | Terraform linting |
| Python 3 | 3.12 | Helper scripts in `scripts/` |

### Lint / Format / Validate

- **Format check:** `terraform fmt -check -recursive` (CI runs this on PRs)
- **Lint:** `tflint --init && tflint` (CI runs this on PRs)
- **Validate (root module):** `terraform init -backend=false && terraform validate`
- **Validate (examples):** `cd examples/<name> && terraform init -backend=false && terraform validate`

### Caveats

- `terraform plan` / `terraform apply` require real AWS credentials and a W&B license key — these are not expected to work in the cloud agent environment.
- The `scripts/get_latest_eks_version.py` script may fail due to AWS docs RSS feed format changes. This is a known upstream issue.
- After `terraform init`, always clean up `.terraform/` directories before committing (they contain downloaded providers/modules and should not be checked in).
- The `.terraform.lock.hcl` file at the root is not committed; each example may have its own lock file.
