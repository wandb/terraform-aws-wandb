# Upgrading the EKS module from v17 to v20

This document describes the changes to `modules/app_eks` that accompany bumping
`terraform-aws-modules/eks/aws` from `~> 17.23` to `~> 20.37`, the implementation
notes a reviewer should know, and how to handle variables that no longer have a
direct equivalent.

## Why this is a breaking change

EKS module v18 (and again in v20) reorganized inputs, outputs, and internal
resource addresses. Even when the resulting cluster is functionally identical,
Terraform sees the module's resources at new addresses, so a plain `apply`
against a cluster created by v17 will try to destroy and recreate the EKS
cluster, node groups, IAM roles, and KMS key. This must be migrated through
state moves, not a destroy-and-recreate.

## Summary of code changes

### `modules/app_eks/main.tf`

| v17 input                              | v20 replacement                                                              |
| -------------------------------------- | ---------------------------------------------------------------------------- |
| `subnets`                              | `subnet_ids`                                                                 |
| `map_accounts` / `map_roles` / `map_users` | `access_entries` (with `authentication_mode = "API_AND_CONFIG_MAP"`)     |
| `cluster_log_retention_in_days`        | `cloudwatch_log_group_retention_in_days`                                     |
| `worker_additional_security_group_ids` | `node_security_group_additional_rules` + per-node-group `vpc_security_group_ids` |
| `cluster_encryption_config` (list)     | `cluster_encryption_config` (single object) + `create_kms_key = false`       |
| `node_groups_defaults`                 | `eks_managed_node_group_defaults`                                            |
| `node_groups`                          | `eks_managed_node_groups`                                                    |

Inside `eks_managed_node_group_defaults` and each entry of
`eks_managed_node_groups`:

| v17 field                              | v20 replacement                                                                                  |
| -------------------------------------- | ------------------------------------------------------------------------------------------------ |
| `subnets`                              | `subnet_ids`                                                                                     |
| `desired_capacity` / `max_capacity` / `min_capacity` | `desired_size` / `max_size` / `min_size`                                                |
| `name_prefix` (single field)           | `name` + `use_name_prefix = true`                                                                |
| `disk_encrypted` / `disk_kms_key_id` / `disk_type` / `disk_size` | nested `block_device_mappings.xvda.ebs.{encrypted, kms_key_id, volume_type, volume_size}` |
| `metadata_http_tokens` / `metadata_http_put_response_hop_limit` | nested `metadata_options.{http_tokens, http_put_response_hop_limit}`     |
| `kubelet_extra_args`                   | `bootstrap_extra_args = "--kubelet-extra-args '...'"`                                            |

`map_roles` and `map_users` are now folded into `access_entries`, keyed by
`username`, with `principal_arn` set to the role/user ARN and the original
`groups` translated to `kubernetes_groups`. RBAC bindings on the cluster that
key on the username string continue to work because the username is preserved
in the access-entry key.

### `modules/app_eks/outputs.tf`

| Output                  | Was                                                                              | Now                                                          |
| ----------------------- | -------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `cluster_name`          | `module.eks.cluster_id`                                                          | `module.eks.cluster_name`                                    |
| `autoscaling_group_names` | hand-rolled walk over `module.eks.node_groups[*].resources[0].autoscaling_groups[0].name` | `module.eks.eks_managed_node_groups_autoscaling_group_names` |
| `cluster_endpoint`      | (not exposed — callers used `data "aws_eks_cluster"`)                            | `module.eks.cluster_endpoint`                                |
| `cluster_certificate_authority_data` | (not exposed — callers used `data "aws_eks_cluster"`)               | `module.eks.cluster_certificate_authority_data`              |

`module.eks.cluster_id` still exists in v20 but its semantics changed in EKS
itself (it is now the cluster ARN-style identifier on some AWS API surfaces),
so we explicitly switch to `cluster_name`.

`cluster_endpoint` and `cluster_certificate_authority_data` are surfaced both
from `modules/app_eks/outputs.tf` and from the root `outputs.tf`. They are not
new outputs of the upstream community module — v17 exposed equivalents — but
they were never re-exported by `terraform-aws-wandb`. See the
[Caller-side kubernetes/helm providers](#caller-side-kuberneteshelm-providers)
section below for why this matters under v20 specifically.

## Implementation notes

### Encryption config conditional

The v17 code had:

```hcl
cluster_encryption_config = var.kms_key_arn != "" ? [{...}] : null
```

In v20 the type is `any` and defaults to an object, not a list. A ternary
returning either an object or `{}` fails Terraform's type unifier
("Inconsistent conditional result types"). The current implementation always
passes the object and lets `provider_key_arn` be empty when the caller didn't
supply a key; AWS rejects an empty `provider_key_arn` only if encryption is
attempted, and `enable_cluster_encryption_config` inside the v20 module gates
this on `length(var.cluster_encryption_config) > 0`. If you want to fully
disable secret encryption when no KMS key is provided, set
`cluster_encryption_config = {}` instead — both branches must be the same
shape.

### Security-group bridging

In v17, `worker_additional_security_group_ids` attached an *additional* SG to
every node, so anything allowed on `aws_security_group.primary_workers`
flowed to nodes. In v20 the analogous wiring lives in two places:

1. `node_security_group_additional_rules` adds an ingress rule to the module's
   own node SG that source-allows traffic from `primary_workers`.
2. `vpc_security_group_ids = [aws_security_group.primary_workers.id]` on each
   managed node group attaches `primary_workers` directly to the ENIs.

Both are needed because the LB / DB / Redis SG rules in this module
(`security_group_rule.lb`, `.database`, `.elasticache`) match
`source_security_group_id = aws_security_group.primary_workers.id`. Without
attaching `primary_workers` to the nodes, those rules wouldn't match real node
traffic.

### Node IAM role

`create_iam_role = false` plus `iam_role_arn = aws_iam_role.node.arn` keeps
the existing `aws_iam_role.node` resource (defined in
`modules/app_eks/iam-roles.tf`) as the node role. Do **not** remove
`aws_iam_role.node` — `iam-role-attachments.tf`, `iam-role-policies.tf`, and
`weave_worker_auth_secret_reader` all attach policies to it by name.

There is a latent ordering hazard worth knowing about, even though it is not
new in v20: the AWS-managed policies on `aws_iam_role.node`
(`AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`,
`AmazonEC2ContainerRegistryReadOnly`, …) are declared as standalone
`aws_iam_role_policy_attachment` resources at the `modules/app_eks` level,
*siblings* of `module.eks`. Nothing inside `module.eks` references them, so
they're not in the dependency chain of `aws_eks_node_group`. In a normal full
`terraform apply` the IAM attachments propagate in seconds while the node
group takes ~5 minutes to provision instances, so the implicit race is won
without anyone noticing. **Any partial apply that targets `module.eks` (or any
of its descendants) without also targeting these attachments will create a
node group whose role has no policies, the kubelet on the launched instances
cannot register, and the node group fails with `NodeCreationFailure: Instances
failed to join the kubernetes cluster`.** If you ever bootstrap with `-target`
(see the [Caller-side kubernetes/helm providers](#caller-side-kuberneteshelm-providers)
section), include all 11 attachments in the target set, or — better — add an
explicit `depends_on` from the node group module call to the attachments so
the dependency is captured in code.

### Duplicate OIDC provider

The community module gates `aws_iam_openid_connect_provider.oidc_provider[0]`
on `enable_irsa`. The default for that flag flipped between versions:

- **v17 default: `false`.** This codebase did not set `enable_irsa`, so the
  community-side resource was never created in state.
  `terraform-aws-wandb`'s own `aws_iam_openid_connect_provider.eks` (defined
  in `modules/app_eks/main.tf`) was the sole manager of that AWS resource.
- **v20 default: `true`.** Without an explicit override, the community module
  now declares the OIDC provider too.

With both layers declared in v20, `terraform apply` tries to create two
`aws_iam_openid_connect_provider` resources for the same OIDC issuer URL.
AWS only permits one provider per URL, so whichever resource is created
second 409s with:

```
EntityAlreadyExists: Provider with url https://oidc.eks.<region>.amazonaws.com/id/<id> already exists
```

The fix is to disable the community module's copy. In the `module "eks"` call
in `modules/app_eks/main.tf`, set:

```hcl
enable_irsa = false
```

`enable_irsa` in the community module only gates `local.create_oidc_provider`
(`main.tf` of `terraform-aws-modules/eks/aws`) — it does not affect cluster
auth, access entries, or any other behavior. The wandb-side OIDC provider
remains the sole owner, and every downstream consumer
(`modules/app_eks/iam-roles.tf` for IRSA, `add-ons.tf`, the `lb_controller` /
`external_dns` / `cluster_autoscaler` submodules' `oidc_provider` inputs) is
already wired to `aws_iam_openid_connect_provider.eks`, not to the community
module's copy.

State migration (in addition to the moves listed in
[State migration](#state-migration) below):

- *Upgrading from v17 with the wandb-side OIDC provider already in state.*
  Add `enable_irsa = false` and apply. The community module's
  `oidc_provider[0]` was never in your state, the wandb-side resource is
  unchanged, and there is nothing to import.
- *Bootstrapping a new cluster on v20 where the community module's resource
  already won the race and is in state* (e.g. a `-target=module.eks` partial
  apply that succeeded before the wandb-side resource ran):

  ```bash
  terraform state rm 'module.app_eks.module.eks.aws_iam_openid_connect_provider.oidc_provider[0]'
  # ... add `enable_irsa = false` to module "eks" ...
  terraform import 'module.app_eks.aws_iam_openid_connect_provider.eks' \
    'arn:aws:iam::<account>:oidc-provider/oidc.eks.<region>.amazonaws.com/id/<id>'
  ```

  Adjust the addresses for your caller's module path (e.g. prefix with
  `module.wandb_infra.` if you're consuming this module from a root module
  named `wandb_infra`). After import, `terraform plan` will show a single
  in-place update on the OIDC provider that drops the
  `Name = "<namespace>-eks-irsa"` and other tags the community module
  stamped at create time — the wandb-side resource doesn't set them, so they
  go away once. There is no flip-flop on subsequent plans.

### Caller-side kubernetes/helm providers

Under v17 the recommended caller pattern was something like:

```hcl
data "aws_eks_cluster" "this" {
  name = module.wandb_infra.cluster_id
}

data "aws_eks_cluster_auth" "this" {
  name = module.wandb_infra.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}
```

This worked on a clean first `terraform apply` because v17's
`module.eks.cluster_id` resolved to `aws_eks_cluster.this[0].id`, an unknown
resource attribute. Terraform deferred `data "aws_eks_cluster"` until after
the cluster was created in the same apply.

In v20, `module.eks.cluster_name` resolves through a `try()` expression that
falls back to `var.cluster_name` (which the wandb_infra module sets to
`var.namespace`). At plan time the data source's `name` argument is therefore
*statically known*, Terraform refreshes the data source eagerly, and a
first-time plan against a not-yet-existent cluster fails:

```
Error: reading EKS Cluster (<namespace>): couldn't find resource
  with data.aws_eks_cluster.this
```

Adding `depends_on = [module.wandb_infra]` to the data sources is **not** a
fix: the kubernetes/helm providers consume the data sources, and resources
inside `module.wandb_infra` (e.g. `kubernetes_storage_class.gp3`,
`helm_release.external_dns`) consume those providers, so the explicit
`depends_on` produces a cycle.

Two options for the caller:

1. *Recommended.* Drop the `data "aws_eks_cluster"` data source entirely and
   wire the providers from the new module outputs:

   ```hcl
   data "aws_eks_cluster_auth" "this" {
     name = module.wandb_infra.cluster_name
   }

   provider "kubernetes" {
     host                   = module.wandb_infra.cluster_endpoint
     cluster_ca_certificate = base64decode(module.wandb_infra.cluster_certificate_authority_data)
     token                  = data.aws_eks_cluster_auth.this.token
   }

   provider "helm" {
     kubernetes {
       host                   = module.wandb_infra.cluster_endpoint
       cluster_ca_certificate = base64decode(module.wandb_infra.cluster_certificate_authority_data)
       token                  = data.aws_eks_cluster_auth.this.token
     }
   }
   ```

   `aws_eks_cluster_auth` is purely client-side (it builds a presigned STS
   request) and does not call AWS, so it succeeds even when the cluster
   hasn't been created yet — only its `name` argument needs to be known.
   The new outputs are themselves derived from the community module's
   `cluster_endpoint` / `cluster_certificate_authority_data`, both of which
   are `try(... , null)` and therefore safely unknown until apply. This
   makes a single full `terraform apply` work end-to-end on a clean
   workspace.

2. *Two-stage `-target` apply.* If you can't change the caller, run
   `terraform apply -target=module.wandb_infra.module.app_eks` first to
   create the cluster, then `terraform apply` for the rest. Targeting
   anything narrower (e.g. `module.eks`) skips the IAM policy attachments —
   see [Node IAM role](#node-iam-role) above for why that breaks node
   group creation. Living with this is workable but means every fresh
   install needs the two-stage dance, and the `-target` plan is fragile to
   future module restructuring.

The `terraform-aws-wandb` upstream change to support option 1 is the two
re-exports added to `outputs.tf` (cluster_endpoint and
cluster_certificate_authority_data) — see [`modules/app_eks/outputs.tf`](#modulesapp_eksoutputstf)
above.

### `kubelet_extra_args` → `bootstrap_extra_args`

In v17 the module rendered a launch-template user-data block that called
`bootstrap.sh --kubelet-extra-args "<value>"`. In v20 the same effect is
expressed by setting `bootstrap_extra_args` on the node group; the module's
user-data template appends it to the bootstrap invocation. Verify on AL2023
nodes — the AL2023 user-data template uses `nodeadm` and a YAML kubelet
config, not the legacy `bootstrap.sh` flag passthrough. If this branch
(`j7m4/AL2023-1`) is moving to AL2023, the `--system-reserved` flag should
move into a `cloudinit_pre_nodeadm` / `cloudinit_post_nodeadm` block writing
into `/etc/kubernetes/kubelet/config.json.d/` rather than
`bootstrap_extra_args`.

## State migration

This module historically created the EKS cluster, KMS key, IAM roles, OIDC
provider, CloudWatch log group, security groups, and node groups under
addresses like:

```
module.app_eks.module.eks.aws_eks_cluster.this[0]
module.app_eks.module.eks.aws_iam_role.cluster[0]
module.app_eks.module.eks.module.node_groups.aws_eks_node_group.workers["ng-0"]
module.app_eks.module.eks.aws_kms_key.cluster[0]
```

In v20 these become:

```
module.app_eks.module.eks.aws_eks_cluster.this[0]                         # same
module.app_eks.module.eks.aws_iam_role.this[0]                            # renamed
module.app_eks.module.eks.module.eks_managed_node_group["ng-0"].aws_eks_node_group.this[0]
module.app_eks.module.eks.module.kms.aws_kms_key.this[0]                  # moved into kms submodule
```

Recommended approach for an existing cluster:

1. Run `terraform plan` after the upgrade and capture the full set of
   "will be destroyed" / "will be created" pairs that point at the same
   underlying AWS resource.
2. Translate each pair into a `moved {}` block (preferred over
   `terraform state mv` so the migration travels with the code). Add them in a
   new file like `modules/app_eks/moved.tf`.
3. Re-plan and confirm the diff is empty (or only attribute drift you actually
   want).
4. Until step 3 is clean, **do not apply**. A bad state move on the EKS
   cluster will mean recreating it, which destroys the data plane.

The KMS key move is the highest-risk one: if the existing key is detached
without `create_kms_key = false`, the v20 module will create a new one and
secret encryption will rotate. The current code sets `create_kms_key = false`
and reuses the externally-passed `var.kms_key_arn`, so this should be a
no-op — verify on plan.

## Dropped variables

### `map_accounts` (`list(string)`, default `[]`)

**What it did for v17.** Populated the `mapAccounts:` key of the `aws-auth`
ConfigMap. Any IAM principal from a listed account ID could authenticate to
the cluster with `username = <their full IAM ARN>` and **no Kubernetes
groups**. Useful only in combination with RBAC bindings that match that ARN
string as a username. The variable was wired all the way through (root
`kubernetes_map_accounts` → submodule `map_accounts` → v17 EKS module's
`mapAccounts`), but its default was `[]`, so the feature was off by default
unless a caller explicitly set the variable.

**Why there is no v20 equivalent.** Access entries require a concrete
`principal_arn` — a specific user or role. "Trust an entire account" is not
expressible.

**Options for handling existing usage.**

1. *Most users — do nothing.* The default is `[]`, so the variable was almost
   certainly never set. Remove it from `modules/app_eks/variables.tf` and from
   the corresponding `kubernetes_map_accounts` variable in the root
   `variables.tf` and `main.tf`. This is the recommended path.

2. *If a caller actually relies on it:* enumerate the specific roles or users
   from those accounts that need cluster access and add them to `map_roles` /
   `map_users` (which now flow into `access_entries`). For programmatic
   migration, a caller can iterate IAM roles in the source account via the
   AWS provider and pipe them into `map_roles`, but this is a behavior change
   the caller should make explicitly — it is not appropriate to do silently
   inside this module.

3. *If you need account-wide trust as a stopgap:* keep the v17 ConfigMap
   pathway alive by setting `authentication_mode = "API_AND_CONFIG_MAP"` (the
   current code already does this) and writing the `aws-auth` ConfigMap
   directly with a `kubernetes_config_map_v1_data` resource that includes a
   `mapAccounts:` block. The v20 module no longer manages this ConfigMap, so
   nothing inside the module will fight you, but you are now responsible for
   keeping it in sync with the access entries the module creates. **Not
   recommended** — it reintroduces the dual-source-of-truth problem that EKS
   access entries were designed to eliminate.

### Dead variables in `modules/app_eks/variables.tf`

After this change, `var.map_accounts` is declared but no longer wired
anywhere. Remove it. `var.map_roles` and `var.map_users` are still in use
(read inside the `access_entries` expression), so leave them.

The corresponding root-module variables (`kubernetes_map_accounts`,
`kubernetes_map_roles`, `kubernetes_map_users`) flow through `main.tf` into
the submodule. Once `map_accounts` is removed from the submodule, also remove
`kubernetes_map_accounts` from the root variables and the README's
`<!-- BEGIN_TF_DOCS -->` block (regenerated by `terraform-docs`).

## Verification checklist

- [ ] `terraform init -upgrade` succeeds.
- [ ] `terraform validate` passes for the module and every example under
      `examples/`.
- [ ] `terraform plan` against an existing v17-managed cluster shows the
      entire `module.app_eks.module.eks.*` tree as moved (via `moved` blocks),
      not destroyed/recreated.
- [ ] `aws-auth` ConfigMap on a freshly created cluster contains the cluster
      creator (because `enable_cluster_creator_admin_permissions = true`) plus
      one entry per item in `map_roles` / `map_users`.
- [ ] Pods on the new node groups can reach RDS, ElastiCache, and the ALB —
      proves the `primary_workers` SG bridging is wired correctly.
- [ ] On AL2023 nodes (if applicable), `kubectl get --raw
      /api/v1/nodes/<node>/proxy/configz` shows the configured
      `systemReserved` values.
- [ ] First `terraform apply` from a clean workspace (no prior state, fresh
      VPC) completes without `-target` and without a 409 on
      `aws_iam_openid_connect_provider.eks`. Proves the `enable_irsa = false`
      change and the new `cluster_endpoint` /
      `cluster_certificate_authority_data` outputs are wired correctly.
- [ ] `terraform state list` after a clean apply contains
      `module.app_eks.aws_iam_openid_connect_provider.eks` and does **not**
      contain `module.app_eks.module.eks.aws_iam_openid_connect_provider.oidc_provider[0]`.
- [ ] A second `terraform plan` immediately after the first apply shows zero
      changes — in particular no churn on the OIDC provider tags and no
      pending update on the kubernetes/helm provider configs.
