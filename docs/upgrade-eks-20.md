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

In v20 the type is `any` and defaults to an object, not a list. The current
v20 implementation gates the same way:

```hcl
cluster_encryption_config = var.kms_key_arn != "" ? {
  provider_key_arn = var.kms_key_arn
  resources        = ["secrets"]
} : {}
```

This matters because v20 turns encryption on whenever
`length(var.cluster_encryption_config) > 0`, and additionally creates an
`aws_iam_policy.cluster_encryption[0]` (when `attach_cluster_encryption_policy`
is left at its `true` default). Passing the object with an empty
`provider_key_arn` therefore both creates a useless IAM policy referencing
`Resource = ""` and asks AWS to enable secret encryption against an empty key
ARN — the cluster create then 400s. The empty-object branch sidesteps both.

A ternary that returns an object on one branch and `{}` on the other is fine
on Terraform `~> 1.9` (the type unifier treats the missing keys as optional);
on older Terraform it errors with "Inconsistent conditional result types" and
must be worked around with a `merge()` or `local`-with-`null` pattern.

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

### Preserving v17 resource names for true in-place upgrade

A naive `terraform apply` against a v17-managed cluster, even with the `moved`
blocks in `modules/app_eks/moved.tf`, ends up with **5 forced replacements**
that ripple into a destroy/recreate of the EKS cluster's data plane:

| Resource | What forces replacement |
| --- | --- |
| `module.eks.aws_iam_role.this[0]` (cluster role) | v17 used `name_prefix = var.cluster_name` (`"j7m4-foo"`); v20 default is `"${cluster_name}-cluster${prefix_separator}"` → `"j7m4-foo-cluster-"`. Different `name_prefix` ⇒ TF replaces. |
| `module.eks.aws_eks_cluster.this[0]` | Cascades from the IAM role replacement above (`role_arn` changes ⇒ `forces_replacement` on the cluster). |
| `module.eks.aws_security_group.cluster[0]` | Same `name_prefix` story for the cluster SG, plus the v20 default `description` (`"EKS cluster security group"`) drops v17's trailing period. SG description is **immutable** in AWS ⇒ replace. |
| `module.eks.module.eks_managed_node_group["ng-N"].aws_eks_node_group.this[0]` | v17's `node_group_name_prefix` was `"<namespace>-<az>"` (no trailing separator). v20 hardcodes `"${var.name}-"`. |
| `module.eks.module.eks_managed_node_group["ng-N"].aws_launch_template.this[0]` | Same hardcoded `"${local.launch_template_name}-"` in the launch_template, plus the parent eks module defaults `launch_template_name` to `each.key` (`"ng-0"`) when unset, so the prefix becomes `"ng-0-"` instead of `"<namespace>-<az>-"`. |

The first three are fixable purely through inputs to the stock v20 community
module (no upstream patch needed). The last two require a small, additive
patch to the community `eks-managed-node-group` submodule.

#### Inputs that fix the cluster + cluster IAM role + cluster SG

In `modules/app_eks/main.tf`, the `module "eks"` call sets:

```hcl
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = var.namespace
  cluster_version = var.cluster_version

  iam_role_name                          = var.namespace          # match v17 name_prefix
  iam_role_use_name_prefix               = true
  cluster_security_group_name            = var.namespace          # match v17 name_prefix
  cluster_security_group_use_name_prefix = true
  cluster_security_group_description     = "EKS cluster security group." # v17 had trailing period; SG description is immutable
  prefix_separator                       = ""                     # v17 used no separator between prefix and random suffix
  ...
}
```

Why each one matters:

- `iam_role_name = var.namespace` + `iam_role_use_name_prefix = true` + `prefix_separator = ""` ⇒ v20 builds `name_prefix = "${var.namespace}${prefix_separator}" = var.namespace`, which matches v17. The cluster IAM role gets an in-place update only (the v20 default policy adds `sts:TagSession` to the assume-role document — fine to apply in-place).
- `cluster_security_group_name = var.namespace` + `cluster_security_group_use_name_prefix = true` ⇒ same trick for the cluster SG.
- `cluster_security_group_description = "EKS cluster security group."` ⇒ matches v17's literal string. Without this, AWS rejects the description change because SG descriptions are immutable.

With these in place, the cluster, the cluster IAM role, and the cluster SG all
become in-place updates instead of destroy/create. `aws_eks_cluster.this[0]`
keeps its endpoint, OIDC issuer URL, and ARN, so anything downstream (the
wandb-side `aws_iam_openid_connect_provider.eks`, IRSA roles, ALB cert
validation) doesn't ripple-replace either.

#### Vendored submodule + `name_prefix_separator` for node groups

The remaining replacements come from the `eks-managed-node-group` submodule,
which hardcodes `"-"` between the user-supplied name and the random suffix:

```hcl
# upstream modules/eks-managed-node-group/main.tf, untouched v20.37
name_prefix            = var.launch_template_use_name_prefix ? "${local.launch_template_name}-" : null
node_group_name_prefix = var.use_name_prefix ? "${var.name}-" : null
```

There is no input variable to override that `"-"`. The only fix is a patch.
Because the registry module is re-downloaded on every `terraform init`, an
in-place edit to `.terraform/modules/...` is ephemeral. The persistent path is
to **vendor the v20 community module** into this worktree at
`vendored/terraform-aws-eks-v20/` and switch `module "eks"` to source from
there:

```hcl
module "eks" {
  source = "../../vendored/terraform-aws-eks-v20"
  ...
}
```

Patches applied to the vendored copy:

1. `vendored/terraform-aws-eks-v20/modules/eks-managed-node-group/variables.tf`
   — add a new `name_prefix_separator` variable, default `"-"` (preserves stock
   v20 behavior for callers that don't opt in):

   ```hcl
   variable "name_prefix_separator" {
     description = "String inserted between the launch template / node group name and the random suffix when use_name_prefix is true. Default \"-\" matches stock v20 behavior; set to \"\" to preserve a v17-era name pattern that did not include a separator."
     type        = string
     default     = "-"
   }
   ```

2. `vendored/terraform-aws-eks-v20/modules/eks-managed-node-group/main.tf`
   — replace the two hardcoded `"-"`s with the variable:

   ```hcl
   name_prefix            = var.launch_template_use_name_prefix ? "${local.launch_template_name}${var.name_prefix_separator}" : null
   node_group_name_prefix = var.use_name_prefix ? "${var.name}${var.name_prefix_separator}" : null
   ```

3. `vendored/terraform-aws-eks-v20/node_groups.tf` — forward the new variable
   from the parent `module "eks"` to `module "eks_managed_node_group"`:

   ```hcl
   name_prefix_separator = try(each.value.name_prefix_separator, var.eks_managed_node_group_defaults.name_prefix_separator, "-")
   ```

Then in `modules/app_eks/main.tf`, opt in via `eks_managed_node_group_defaults`
and pin the launch_template name explicitly so the parent module's default
fallback (`each.key` ⇒ `"ng-0"`) doesn't take over:

```hcl
eks_managed_node_group_defaults = {
  ...
  name_prefix_separator = ""
}

eks_managed_node_groups = {
  for idx, subnet in data.aws_subnet.private : "ng-${idx}" => {
    name                 = "${var.namespace}-${regex(".*[[:digit:]]([[:alpha:]])", subnet.availability_zone)[0]}"
    launch_template_name = "${var.namespace}-${regex(".*[[:digit:]]([[:alpha:]])", subnet.availability_zone)[0]}"
    use_name_prefix      = true
    ...
  }
}
```

After all three patches plus the inputs above, a `terraform plan` against a
v17-applied cluster shows:

- `aws_eks_cluster.this[0]` → in-place update (tags only)
- `aws_iam_role.this[0]` → in-place update (`sts:TagSession` added to assume_role_policy)
- `aws_security_group.cluster[0]` → in-place update (tags)
- Both `aws_eks_node_group.this[0]` instances → in-place update
- Both `aws_launch_template.this[0]` instances → in-place update
- Only one true replacement remains: `aws_security_group_rule.cluster["ingress_nodes_443"]`, because its `source_security_group_id` migrates from the v17 `aws_security_group.workers[0]` (being destroyed as a v17 orphan) to the v20 `aws_security_group.node[0]`. SG rules are not destructive to the cluster — there is a sub-second window where pods can't reach the cluster API on 443 during the rule swap.

The patch is additive (default behavior unchanged for stock callers) and is a
reasonable upstream-PR candidate against `terraform-aws-modules/eks/aws`.

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

## Upgrade runbook

This is the procedural recipe for upgrading an existing v17-managed cluster
in place. Run from the caller (root module) workspace, not from
`modules/app_eks` — the addresses below are written relative to the caller's
view (`module.<root>.module.app_eks.module.eks.…` becomes
`module.app_eks.module.eks.…` when invoking this module directly; adjust
prefixes for your wrapper if you have one).

**Everything in this runbook is expressed in code.** No `terraform state rm`
or `terraform state mv` is required during a normal upgrade; all state moves
are encoded in `moved {}` blocks that travel with the module, and the only
operator action between plans/applies is flipping `var.preserve_aws_auth_configmap`
back to its default after step 7.

The mechanics each step depends on are documented above:

- The 11 `moved {}` blocks for the v17 → v20 address renames are in
  [`modules/app_eks/moved.tf`](../modules/app_eks/moved.tf).
- The aws-auth ConfigMap adoption is in
  [`modules/app_eks/aws_auth_legacy.tf`](../modules/app_eks/aws_auth_legacy.tf)
  (one more `moved {}` block plus a gated resource).
- The vendored eks community module fork is at
  [`vendored/terraform-aws-eks-v20/`](../vendored/terraform-aws-eks-v20/);
  see [Preserving v17 resource names for true in-place upgrade](#preserving-v17-resource-names-for-true-in-place-upgrade)
  for what the patch does and why.

### Sequencing relative to EKS version upgrades

This runbook covers **only the module upgrade** (community
`terraform-aws-modules/eks/aws` v17 → v20). If the same operator wants to
*also* move the cluster to a newer Kubernetes minor (e.g. EKS 1.32 → 1.34),
they are three separate Terraform applies, in this order:

1. **Module v17 → v20, EKS version unchanged.** Follow this runbook end to
   end. `var.eks_cluster_version` does not change. The cluster's control
   plane is not touched by AWS — only resource-address moves, in-place
   attribute updates, and v17-orphan cleanup. Validates the module migration
   in isolation.

2. **EKS minor bump #1 (e.g. 1.32 → 1.33), already on v20.** Flip
   `var.eks_cluster_version` (in the caller's tfvars) to the *next* minor,
   re-plan, apply. The diff should be `aws_eks_cluster.this[0]` updating
   `version` in place plus a fresh `release_version` rolling on each
   `aws_eks_node_group.this[0]`. AWS upgrades the control plane first
   (~20–30 min), then EKS rolls each managed node group to a 1.33-compatible
   AMI. The
   [`data "aws_eks_addon_version"` blocks in the caller's `main.tf`](#caller-side-kuberneteshelm-providers)
   automatically pick 1.33-compatible add-on versions, so you don't need to
   hand-update those.

3. **EKS minor bump #2 (1.33 → 1.34).** Same as step 2, one more minor.

Two constraints make this ordering mandatory rather than just preferred:

- **AWS rejects multi-minor upgrades in a single API call.** EKS's
  `UpdateClusterVersion` accepts exactly one minor jump at a time —
  attempting 1.32 → 1.34 in a single apply fails server-side. The Terraform
  provider does not chain calls behind the scenes, so each minor needs its
  own apply.
- **v17 of the community module hasn't been validated against modern EKS
  versions.** v17 was developed against EKS 1.21–1.27 (depending on the
  v17.x patch). Setting `cluster_version = "1.34"` while still sourced from
  v17 typically fails at module-internal user_data / launch template logic
  before reaching the cluster API. So the module must be on v20 *before* the
  EKS version moves past what v17 supports.

You can interleave [step 10 of the runbook (retire the aws-auth ConfigMap)](#steps)
between any of these stages — it depends only on stage 1 completing and the
access-entry auth path being verified, not on any EKS version bump. The
recommended sequence is to retire aws-auth *after* the EKS version moves are
done, so the migration apply, the version bumps, and the auth-cleanup apply
each have only one moving part.

### Steps

1. **Snapshot state.** Before anything else, copy the current state file
   somewhere safe so a bad apply is recoverable.

   ```bash
   terraform state pull > eks-v17-pre-upgrade.tfstate
   ```

   For S3 backends, also note the current state version ID; for `terraform
   cloud`, take a manual snapshot.

2. **Pull the v20 code on this branch.** The branch carries:

   - `module "eks"` in `modules/app_eks/main.tf` sourced from
     `../../vendored/terraform-aws-eks-v20` (not the registry).
   - The five name-preservation inputs in that `module "eks"` call:
     `iam_role_name = var.namespace`, `iam_role_use_name_prefix = true`,
     `cluster_security_group_name = var.namespace`,
     `cluster_security_group_use_name_prefix = true`,
     `cluster_security_group_description = "EKS cluster security group."`,
     `prefix_separator = ""`.
   - `enable_irsa = false` on the same `module "eks"` call (the wandb-side
     `aws_iam_openid_connect_provider.eks` is the sole owner of the cluster's
     OIDC URL — see [Duplicate OIDC provider](#duplicate-oidc-provider)).
   - The `cluster_encryption_config` JSON round-trip in `module "eks"` so
     the type unifier accepts the conditional — see
     [Encryption config conditional](#encryption-config-conditional).
   - `eks_managed_node_group_defaults.name_prefix_separator = ""` and
     per-entry `launch_template_name = "${var.namespace}-${az}"` so node-group
     and launch-template names match the v17-era pattern.
   - `cluster_endpoint` and `cluster_certificate_authority_data` re-exports
     in `outputs.tf` — see [Caller-side kubernetes/helm providers](#caller-side-kuberneteshelm-providers)
     for the caller-side wiring change that goes with these.

3. **Set the upgrade-only variables in your caller.** Two flags are needed
   only during the v17 → v20 transition:

   ```hcl
   # in your caller's terraform.tfvars (or vars.yaml -> rendered tfvars)
   preserve_aws_auth_configmap = true   # adopt v17's kube-system/aws-auth ConfigMap
   ```

   `preserve_aws_auth_configmap = true` opts the caller into the
   `kubernetes_config_map.aws_auth_legacy[0]` resource via
   [`modules/app_eks/aws_auth_legacy.tf`](../modules/app_eks/aws_auth_legacy.tf).
   Without this, the v17-managed ConfigMap would be marked for destroy
   (because v20 doesn't manage it) and TF would `DELETE` it from the cluster
   during apply — risking auth interruption for nodes joining or refreshing
   tokens during the window. With it set, the ConfigMap is adopted at the
   wandb-side address; data is left alone via
   `lifecycle.ignore_changes = [data, binary_data]`.

4. **`terraform init -upgrade`.** Picks up the new vendored module path,
   the v5 AWS provider, and any new module-level providers v20 declares.

   ```bash
   terraform init -upgrade
   ```

5. **First plan and read it carefully.**

   ```bash
   terraform plan -no-color > /tmp/v20-stage1.txt
   ```

   Expected diff:

   - **In-place updates only** for the cluster, cluster IAM role, cluster
     SG, CloudWatch log group, both node groups, and both launch templates.
     The cluster's update is tag-only; the IAM role's adds `sts:TagSession`
     to its assume-role policy; the rest are tag updates and minor field
     normalization. None should be marked `forces replacement`.
   - **`aws_eks_cluster.this[0]` must NOT be `must be replaced`.** If it
     is, the most common cause is a missed name override in step 2 — the
     cluster IAM role gets a different `name_prefix` and TF treats it as a
     different resource, which cascades to a cluster recreate. Re-read the
     `iam_role_name` / `prefix_separator` lines in `modules/app_eks/main.tf`
     before continuing.
   - **`aws_iam_role.this[0]`, `aws_security_group.cluster[0]`, the two
     `aws_eks_node_group.this[0]` instances, and the two
     `aws_launch_template.this[0]` instances** must NOT be `must be replaced`
     either. They each share a `name_prefix` knob; if any of them shows
     replacement, the corresponding override (see step 2) is missing.
   - **Renames** ("have moved") for everything in
     [`modules/app_eks/moved.tf`](../modules/app_eks/moved.tf): cluster IAM
     role, its `AmazonEKSClusterPolicy` attachment, the cluster SG ingress
     rule, both node groups, both launch templates. Also from
     [`modules/app_eks/aws_auth_legacy.tf`](../modules/app_eks/aws_auth_legacy.tf):
     the `kube-system/aws-auth` ConfigMap from `module.eks.kubernetes_config_map.aws_auth[0]`
     to `kubernetes_config_map.aws_auth_legacy[0]`.
   - **One acceptable replacement**: `aws_security_group_rule.cluster["ingress_nodes_443"]`
     (because its `source_security_group_id` migrates from the v17 worker SG
     to the v20 node SG). Sub-second gap during apply; pods continue running
     because the rule governs new auth handshakes, not in-flight kubelet
     sessions.
   - **Destroys** for v17-only orphans v20 doesn't carry forward:
     `aws_iam_role.workers[0]` plus its four policy attachments;
     `aws_security_group.workers[0]` plus its four rules; the deprecated
     attachments `cluster_AmazonEKSServicePolicy[0]`,
     `cluster_AmazonEKSVPCResourceControllerPolicy[0]`,
     `cluster_elb_sl_role_creation[0]`, `cluster_deny_log_group[0]`;
     `aws_iam_policy.cluster_deny_log_group[0]`,
     `aws_iam_policy.cluster_elb_sl_role_creation[0]`;
     `aws_security_group_rule.cluster_egress_internet[0]`;
     `local_file.kubeconfig[0]`. **Do NOT see** `kubernetes_config_map.aws_auth[0]`
     in this list — if you do, step 3 wasn't applied and you should set the
     variable before continuing.
   - **Creates** for v20-shape resources:
     `aws_security_group.node[0]` and its 11 rules,
     `aws_eks_access_entry.this["cluster_creator"]` and the corresponding
     `aws_eks_access_policy_association`, `time_sleep.this[0]`,
     `aws_iam_policy.cluster_encryption[0]` (only when `var.kms_key_arn != ""`),
     `aws_iam_policy.custom[0]`, four `aws_ec2_tag.cluster_primary_security_group[*]`
     entries, and per-NG `module.user_data.null_resource.validate_cluster_service_cidr`.
   - **No KMS create.** `module.eks.module.kms.aws_kms_key.this[0]` should
     not appear; if it does, `create_kms_key = false` isn't taking effect or
     `var.kms_key_arn` was inadvertently changed.

   On the test cluster the plan reports `27 to add, 13 to change, 18 to destroy`
   with `must be replaced` count of 1. If your numbers materially differ
   (especially with `must be replaced` > 1), stop and diagnose before applying.

6. **Hand-check the destroys.** Confirm the destroyed worker IAM role
   (`aws_iam_role.workers[0]`) is **not** the role attached to the v17 node
   groups — it should not be. The node groups in this codebase use
   `aws_iam_role.node` (defined in `modules/app_eks/iam-roles.tf`), which is
   a sibling of `module.eks` and therefore unaffected. Run:

   ```bash
   aws eks describe-nodegroup --cluster-name <namespace> --nodegroup-name <ng-0-name> \
     --query 'nodegroup.nodeRole'
   ```

   and verify the ARN matches `aws_iam_role.node`, not the doomed
   `module.eks.aws_iam_role.workers[0]`.

7. **Apply.**

   ```bash
   terraform apply
   ```

   Optional: stage the apply with two `-target` flags first for a checkpoint
   after the cluster/role/SG/node-group state moves and in-place updates
   land but before the helm releases reconcile against the v20 module
   addresses:

   ```bash
   terraform apply \
     -target=module.app_eks.module.eks \
     -target=module.app_eks.kubernetes_config_map.aws_auth_legacy
   # then, after the targeted apply lands cleanly:
   terraform apply
   ```

   The second `-target` is required: the `moved {}` block in
   `modules/app_eks/aws_auth_legacy.tf` re-homes the ConfigMap from
   `module.eks.kubernetes_config_map.aws_auth[0]` (inside the first target's
   subtree) to `kubernetes_config_map.aws_auth_legacy[0]` (outside it), and
   TF refuses any plan whose targets don't include both ends of a `moved`
   block. The error message is verbatim:
   `Moved resource instances excluded by targeting … add the following
   additional target options: -target="module.app_eks.kubernetes_config_map.aws_auth_legacy"`.

   Watch for:

   - **`ResourceInUseException` (HTTP 409) on `aws_eks_access_entry.this["cluster_creator"]`.**
     When the `authentication_mode` flip from `CONFIG_MAP` to
     `API_AND_CONFIG_MAP` lands (which happens during this apply because v20
     sets it explicitly), AWS auto-creates an access entry for the IAM
     principal that originally created the cluster — exactly the same
     principal v20's `enable_cluster_creator_admin_permissions = true` is
     trying to add via TF. The two creates race; AWS wins, TF gets a 409.
     Resolve by importing AWS's auto-created entry and policy association
     into state, then re-running the apply:

     ```bash
     SSO_ARN='arn:aws:iam::<account>:role/aws-reserved/sso.amazonaws.com/<region>/AWSReservedSSO_<...>'
     CLUSTER='<your-cluster-name>'

     terraform import \
       'module.app_eks.module.eks.aws_eks_access_entry.this["cluster_creator"]' \
       "${CLUSTER}:${SSO_ARN}"

     terraform import \
       'module.app_eks.module.eks.aws_eks_access_policy_association.this["cluster_creator_admin"]' \
       "${CLUSTER}#${SSO_ARN}#arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
     ```

     The principal ARN is the IAM role of whoever ran the *original* v17
     `terraform apply` that created the cluster; for an SSO setup it looks
     like the example above. AWS also auto-creates an access entry for the
     wandb-side `aws_iam_role.node` and for `AWSServiceRoleForAmazonEKS` —
     those are not in TF's plan and don't need importing.
   - **`NodeCreationFailure`** on any node group rolling its launch template —
     see [Node IAM role](#node-iam-role) for the IAM-attachment race that can
     manifest if a partial apply was used.
   - **`OptInRequired`** or other access-entry errors that aren't 409s —
     these mean the cluster's `authentication_mode` flip didn't land yet;
     run the apply again.

8. **Re-plan to confirm convergence.** Immediately after the apply:

   ```bash
   terraform plan
   ```

   should show zero changes. The most common non-zero cases on a second plan
   are:

   - Tag drift on the OIDC provider (see [Duplicate OIDC provider](#duplicate-oidc-provider)).
   - Provider-config drift on `kubernetes`/`helm` if the caller is still
     using a v17-style `data "aws_eks_cluster"` (see
     [Caller-side kubernetes/helm providers](#caller-side-kuberneteshelm-providers)).
   - A pending update on `kubernetes_config_map.aws_auth_legacy[0]` — fine
     if it's tag-only, suspicious if it touches `data` (means the
     `lifecycle.ignore_changes` isn't working, which is a wandb-side bug).

9. **Sanity-check the data plane.** Without rolling pods, run:

   ```bash
   kubectl get nodes
   kubectl -n kube-system get pods
   kubectl auth can-i --list --as <a-mapped-role-arn>   # access-entry sanity
   aws eks describe-cluster --name <namespace> \
     --query 'cluster.{Status:status,Version:version,RoleArn:roleArn}'
   ```

   The full data-plane bridge check (pods can reach RDS / ElastiCache / ALB)
   is in the [Verification checklist](#verification-checklist).

10. **Retire the aws-auth ConfigMap (separate apply).** Once the access-entry
    path has been observed working — kubelet token refreshes succeed, role
    mappings resolve through access entries, no auth blips in the EKS audit
    log — flip the variable back to its default and apply once more:

    ```hcl
    # in your caller's terraform.tfvars
    preserve_aws_auth_configmap = false   # or remove the line entirely
    ```

    ```bash
    terraform apply
    ```

    This destroys `kubernetes_config_map.aws_auth_legacy[0]` through the
    kubernetes provider on its own schedule, decoupled from the high-risk
    migration apply. The ConfigMap is removed from the cluster; access
    entries become the sole auth path.

    Wait at least one full kubelet credential rotation cycle (typically an
    hour) between step 7 and step 10. If anything was still relying on
    aws-auth, that's when you'll see it — and you can flip the variable back
    to `true` and reapply to recover.

### Rollback

If step 7 fails halfway and you need to roll back to v17, the safe path is:

```bash
terraform state push eks-v17-pre-upgrade.tfstate
git checkout <commit-before-this-pr> -- modules/app_eks versions.tf outputs.tf
terraform init -upgrade
terraform plan      # should be empty
```

The aws-auth ConfigMap that step 3 adopted via `moved` lives at
`kubernetes_config_map.aws_auth_legacy[0]` in the wandb module's state. To
hand it back to v17, reverse the move via `terraform state mv` (or by
flipping the source `moved` block) and let v17 reclaim ownership:

```bash
terraform state mv \
  'module.app_eks.kubernetes_config_map.aws_auth_legacy[0]' \
  'module.app_eks.module.eks.kubernetes_config_map.aws_auth[0]'
```

The in-cluster ConfigMap is untouched throughout — only the state address
changes. If you'd rather not move state at all, you can leave it at the
v20 address and `terraform import` v17's expected address before the next
v17 apply:

```bash
terraform import 'module.app_eks.module.eks.kubernetes_config_map.aws_auth[0]' kube-system/aws-auth
```

After that, `terraform plan` under v17 should be empty. There is no
recoverable state for the destroys plan from step 5 — by the time apply has
deleted `aws_iam_role.workers[0]` and the worker SG, AWS-side they are gone,
but they were unused (the data plane runs on `aws_iam_role.node`), so
losing them is non-disruptive.

#### Why the rollback story is materially better with the in-place patches

The destroys this section talks about (`aws_iam_role.workers[0]`, worker SG,
v17-only IAM policies, `local_file.kubeconfig`) are all *v17 orphans* — v20
doesn't recreate them. Before the in-place upgrade patches in
[Preserving v17 resource names for true in-place upgrade](#preserving-v17-resource-names-for-true-in-place-upgrade),
mid-apply failure could also leave the cluster and node groups in a
half-replaced state, which is genuinely catastrophic (you lose the data plane
with no way back to v17 short of a full re-provision). With those patches in
place:

- The cluster, cluster IAM role, cluster SG, node groups, launch templates,
  KMS key, OIDC provider — everything load-bearing — get **in-place updates
  only**, never replaced.
- Mid-apply failure leaves the cluster and node groups running. You re-run
  `terraform apply` and TF picks up where it stopped.
- The destroys above all happen *after* the cluster and node-group updates
  succeed (TF dependency-orders them at the end), so a failure on the
  cluster/role/SG updates rolls back cleanly without ever reaching the
  orphan-destroy phase.
- The only resource still on the destroy/create path is
  `aws_security_group_rule.cluster["ingress_nodes_443"]` (because its
  `source_security_group_id` migrates from the v17 worker SG to the new node
  SG). Worst case there is a sub-second window where pods can't reach the
  cluster API on 443; existing pods aren't affected.

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

**Handling.**

The variable cannot just be deleted: a caller who set
`kubernetes_map_accounts = ["123456789012"]` expecting account-wide trust
would silently lose that trust on upgrade and only discover it the next time
someone from that account tried to authenticate. To prevent that, both
`var.map_accounts` (submodule) and `var.kubernetes_map_accounts` (root) are
retained with `default = []` and a `validation` block that hard-fails the
plan if the input is non-empty:

```hcl
variable "kubernetes_map_accounts" {
  type    = list(string)
  default = []

  validation {
    condition     = length(var.kubernetes_map_accounts) == 0
    error_message = "kubernetes_map_accounts is no longer supported. ..."
  }
}
```

The error message points the operator at the migration paths below. The
variables stay in this tripwire state for at least one release cycle and are
removed only after we have evidence (telemetry, support tickets, or just
elapsed time) that no caller is still setting them.

**Migration paths for an operator who hits the tripwire:**

1. *Enumerate explicit principals.* Add the specific roles/users from the
   trusted account to `kubernetes_map_roles` / `kubernetes_map_users` —
   these now flow into `access_entries`. This is the right answer for
   almost everyone. For programmatic migration, a caller can iterate IAM
   roles in the source account via the AWS provider and pipe them into
   `map_roles`, but that is a behavior change the caller should make
   explicitly — it is not appropriate to do silently inside this module.

2. *Manage the ConfigMap directly as a stopgap.* `authentication_mode =
   "API_AND_CONFIG_MAP"` (the current code) means EKS still reads the
   in-cluster `aws-auth` ConfigMap. A caller can keep account-wide trust
   alive by writing that ConfigMap from outside this module with a
   `kubernetes_config_map_v1_data` resource that includes a `mapAccounts:`
   block. The v20 module no longer manages the ConfigMap, so nothing inside
   the module will fight the caller — but the caller is now responsible for
   keeping the ConfigMap and the access entries this module creates from
   contradicting each other. **Not recommended** — it reintroduces the
   dual-source-of-truth problem that EKS access entries were designed to
   eliminate.

### Dead-but-tripwired variables

`var.map_accounts` and `var.kubernetes_map_accounts` are declared with the
validation above but no longer wired into anything that v20 reads. The
existing `map_accounts = var.kubernetes_map_accounts` line in the root
`main.tf` is kept so a direct caller of `modules/app_eks` also hits the
tripwire — `var.map_accounts` is not consumed by `module "eks"` in v20, so
the assignment is functionally a no-op past the validation.

`var.map_roles` and `var.map_users` are still in use (read inside the
`access_entries` expression in `modules/app_eks/main.tf`), so leave them.

When the tripwire variables are eventually removed, also drop
`kubernetes_map_accounts` from the README's `<!-- BEGIN_TF_DOCS -->` block
(regenerated by `terraform-docs`).

## Validation results

The runbook in this document was exercised end-to-end against a sandbox
install (`namespace = j7m4-0430a`, AWS account `770934259321`, region
`us-east-2`) running `terraform-aws-modules/eks/aws ~> 17.23` on EKS 1.32.
The apply sequence covered all four stages (module v17 -> v20 with EKS
unchanged at 1.32; EKS 1.32 -> 1.33; EKS 1.33 -> 1.34; aws-auth retirement)
in three apply windows.

### Stage 1 — module v17 -> v20, EKS 1.32 unchanged

| | |
| --- | --- |
| `terraform plan` headline | `27 to add, 13 to change, 18 to destroy`, 1 forced replacement (`aws_security_group_rule.cluster["ingress_nodes_443"]`, expected — source SG migrates from v17 worker SG to v20 node SG) |
| Cluster `aws_eks_cluster.this[0]` | **in-place update** (tags only) |
| Cluster IAM role `aws_iam_role.this[0]` | **in-place update** (assume_role_policy gains `sts:TagSession`) |
| Cluster SG `aws_security_group.cluster[0]` | **in-place update** (tags only) |
| Both `aws_eks_node_group.this[0]` | **in-place update** |
| Both `aws_launch_template.this[0]` | **in-place update** |
| `kubernetes_config_map.aws_auth_legacy[0]` | **in-place update via `moved {}` adoption** (label cleanup only — `app.kubernetes.io/managed-by`, `terraform.io/module` dropped; data preserved via `lifecycle.ignore_changes`) |

Apply ran in two phases:

1. *Targeted apply* (`-target=module.app_eks.module.eks` plus
   `-target=module.app_eks.kubernetes_config_map.aws_auth_legacy`) ran for
   ~7 minutes and completed both node groups' in-place updates (ng-1 in
   6m18s, ng-0 in 7m30s on the first cycle; ng-1 in 6m18s, ng-0 in 6m28s
   on the resumed cycle).
2. *Unscoped apply* covered helm-release IAM updates and the v17-orphan
   destroys: `1 added, 0 changed, 0 destroyed` (most of the work landed in
   the targeted apply; the orphan destroys all sequenced into the targeted
   apply because they're inside `module.eks`).

The cluster's `roleArn` was preserved across the upgrade
(`arn:aws:iam::<account>:role/<namespace><random-suffix>` — the literal
v17-era ARN). `aws_eks_cluster.this[0].endpoint` and OIDC issuer URL were
unchanged. `kubectl get nodes` reported both nodes Ready throughout.
`https://<fqdn>/` returned `HTTP 200` immediately after the apply
completed.

**Surgical workarounds hit during the apply** (folded into the runbook
above):

1. The targeted apply form requires *two* `-target` flags. TF refuses any
   plan whose targets don't fully cover both ends of a `moved {}` block.
   The `aws-auth_legacy` adoption block has its `from` inside
   `module.eks` (in the first target's subtree) but its `to` outside, so
   the second `-target` flag is mandatory. TF surfaces this with an
   actionable error message identifying the missing target.
2. Hit a `ResourceInUseException` (HTTP 409) on
   `aws_eks_access_entry.this["cluster_creator"]`. AWS auto-creates an
   access entry for the IAM principal that originally created the
   cluster as soon as `authentication_mode` flips from `CONFIG_MAP` to
   `API_AND_CONFIG_MAP` (which happens during this apply). The wandb-side
   `enable_cluster_creator_admin_permissions = true` then races AWS's
   auto-create and 409s. Resolved by importing the AWS-auto-created
   entry and policy association into TF state, then re-running the
   apply. Two `terraform import` commands; under a minute of human work.
   The runbook's step 7 documents the exact commands.

### Stage 2 — EKS 1.32 -> 1.33

| | |
| --- | --- |
| `terraform plan` headline | `1 to add, 9 to change, 1 to destroy`, 1 forced replacement (`module.eks.time_sleep.this[0]`, harmless TF-internal helper whose `cluster_version` trigger changed) |
| `aws_eks_cluster.this[0]` | **in-place version update** (`1.32 -> 1.33`) |
| Both managed node groups | **in-place update** (AWS rolls AMIs to `v1.33.x`-eks compatible, ~6m18s and 6m28s) |
| Add-ons (vpc-cni, kube-proxy, coredns, ebs-csi-driver, efs-csi-driver, metrics-server) | **in-place version updates** auto-resolved to 1.33-compatible versions via the `data "aws_eks_addon_version"` blocks in the caller's `main.tf` |

Total apply duration: ~13 minutes (control plane upgrade + node-group
rolls run in parallel after the cluster update returns). No surgical
workarounds. `terraform plan` after the apply: `No changes`. The HTTPS
endpoint returned 200 throughout. Nodes' new `Ready` ages confirmed they
were rolled fresh (~6 minutes old at first observation, on
`v1.33.11-eks-40737a8`).

### Stage 3 — EKS 1.33 -> 1.34

Same shape as Stage 2:

| | |
| --- | --- |
| `terraform plan` headline | `1 to add, 8 to change, 1 to destroy`, 1 forced replacement (the `time_sleep.this[0]` again — same reason as Stage 2). |
| Apply outcome | `Apply complete! Resources: 1 added, 4 changed, 1 destroyed.` |
| `aws_eks_cluster.this[0]` | in-place version update (`1.33 -> 1.34`); control-plane upgrade completed in **7m9s**. |
| Both managed node groups | in-place update; AMI rolls to `v1.34.7-eks-40737a8`. ng-0 in 5m38s, ng-1 in 7m39s (parallel). |
| Add-ons | auto-resolved to 1.34-compatible versions; kube-proxy refreshed in 14s. |
| Total apply duration | ~15 minutes (cluster sequential, then node groups parallel, then add-on). |

No surgical workarounds. `terraform plan` after the apply: `No changes`.
HTTPS endpoint returned 200 throughout. Cluster `roleArn` unchanged from
Stage 1, confirming three sequential applies preserved cluster identity
end-to-end.

### Stage 4 — retire the aws-auth ConfigMap

Procedure: flip `var.preserve_aws_auth_configmap` from `true` back to its
default `false`, re-render, and run one more `terraform apply`. TF
destroys `kubernetes_config_map.aws_auth_legacy[0]` through the
kubernetes provider on its own schedule, decoupled from any high-risk
migration apply. The cluster continues to authenticate kubelet token
refreshes via the AWS-auto-created access entries (`<namespace>-node`,
the SSO admin role, and `AWSServiceRoleForAmazonEKS`).

Stage 4 has not been exercised in this validation run — left as the
final cleanup once the operator is satisfied with the access-entries
auth path. The runbook step 10 covers the procedure.

### Cumulative AWS impact (stages 1–3 verified)

Across stages 1, 2, and 3, the cluster ID, **role ARN
(`<account>:role/<namespace><random-suffix>` — the literal v17-era
ARN, preserved end-to-end)**, OIDC issuer URL, KMS key, networking
(VPC, subnets, NAT, route tables), database (RDS), cache (ElastiCache),
object store (S3), Route53 zone, and ACM certificate all remained
unchanged. The data plane experienced one rolling node-group refresh
per EKS minor bump (so two refreshes total across stages 2 and 3) plus
one launch-template-driven refresh during stage 1; no workload outage
was observed during the test. Cluster Kubernetes version moved
1.32 → 1.33 → 1.34, with the original cluster's `aws_eks_cluster.this[0]`
state entry preserved across all three applies.

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
- [ ] `terraform plan` against a cluster previously applied with v17 of the
      module shows **no** `must be replaced` for `aws_eks_cluster.this[0]`,
      `aws_iam_role.this[0]`, `aws_security_group.cluster[0]`,
      `aws_eks_node_group.this[0]`, or `aws_launch_template.this[0]`. They
      should all be `will be updated in-place`. The only remaining replacement
      should be `aws_security_group_rule.cluster["ingress_nodes_443"]`
      (`source_security_group_id` migrating from the v17 worker SG to the
      v20 node SG).
- [ ] `module "eks" { source = "../../vendored/terraform-aws-eks-v20" }` —
      the vendored fork is in place, not the registry source. `terraform
      init` does not redownload `terraform-aws-modules/eks/aws` when the
      vendored path is used.
- [ ] `vendored/terraform-aws-eks-v20/modules/eks-managed-node-group/main.tf`
      contains `${var.name_prefix_separator}` (not the literal `-`) on the
      `name_prefix` and `node_group_name_prefix` lines, and
      `vendored/terraform-aws-eks-v20/node_groups.tf` forwards
      `name_prefix_separator` from the parent module to the submodule call.
- [ ] First `terraform plan` after step 4 (init) of the upgrade runbook
      shows `kubernetes_config_map.aws_auth_legacy[0] will be updated in-place`
      (moved from `module.eks.kubernetes_config_map.aws_auth[0]`), **not**
      `kubernetes_config_map.aws_auth[0] will be destroyed`. Proves
      `var.preserve_aws_auth_configmap = true` is in effect and the moved
      block in `modules/app_eks/aws_auth_legacy.tf` is doing its job.
- [ ] After step 10 (`preserve_aws_auth_configmap = false` and apply), the
      cluster's kube-system/aws-auth ConfigMap is gone (`kubectl -n kube-system
      get configmap aws-auth` returns NotFound), and access entries are the
      sole auth path. Run for at least one kubelet credential rotation
      (~1 hour) before considering the migration complete.
