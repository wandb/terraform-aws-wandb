# Upgrading the EKS module from v17 to v20

This document describes the changes to `modules/app_eks` that accompany bumping
`terraform-aws-modules/eks/aws` from `~> 17.23` to `~> 20.37`, the implementation
notes a reviewer should know, and how to handle variables that no longer have a
direct equivalent.

> **Variant note.** This branch implements the v17 → v20 upgrade against the
> stock `terraform-aws-modules/eks/aws ~> 20.37` registry module — there is no
> vendored fork. The tradeoff: the per-AZ `aws_launch_template` and
> `aws_eks_node_group` resources are _replaced_ on the upgrade apply (because
> stock v20 hardcodes a `"-"` separator in `name_prefix` that v17 did not have,
> and `name_prefix` is `ForceNew`). The replacement is graceful — both
> resources have `lifecycle.create_before_destroy = true` in v20 — but the
> apply does roll the data plane through one extra rolling node-roll on top
> of what a normal EKS K8s minor-version bump would do. See
> [Accepted replacement of node groups and launch templates](#accepted-replacement-of-node-groups-and-launch-templates)
> for the details. A sibling branch (`j7m4/v17to20varPrep`) carries a vendored
> fork of the v20 module that avoids this replacement at the cost of ~14k
> lines of vendored Terraform; if you need zero data-plane churn at module-bump
> time, use that branch instead.

## Why this is a breaking change

EKS module v18 (and again in v20) reorganized inputs, outputs, and internal
resource addresses. Even when the resulting cluster is functionally identical,
Terraform sees the module's resources at new addresses, so a plain `apply`
against a cluster created by v17 will try to destroy and recreate the EKS
cluster, node groups, IAM roles, and KMS key. This must be migrated through
state moves, not a destroy-and-recreate.

## Summary of code changes

### `modules/app_eks/main.tf`

| v17 input                                  | v20 replacement                                                                  |
| ------------------------------------------ | -------------------------------------------------------------------------------- |
| `subnets`                                  | `subnet_ids`                                                                     |
| `map_accounts` / `map_roles` / `map_users` | `access_entries` (with `authentication_mode = "API_AND_CONFIG_MAP"`)             |
| `cluster_log_retention_in_days`            | `cloudwatch_log_group_retention_in_days`                                         |
| `worker_additional_security_group_ids`     | `node_security_group_additional_rules` + per-node-group `vpc_security_group_ids` |
| `cluster_encryption_config` (list)         | `cluster_encryption_config` (single object) + `create_kms_key = false`           |
| `node_groups_defaults`                     | `eks_managed_node_group_defaults`                                                |
| `node_groups`                              | `eks_managed_node_groups`                                                        |

Inside `eks_managed_node_group_defaults` and each entry of
`eks_managed_node_groups`:

| v17 field                                                        | v20 replacement                                                                                                                   |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| `subnets`                                                        | `subnet_ids`                                                                                                                      |
| `desired_capacity` / `max_capacity` / `min_capacity`             | `desired_size` / `max_size` / `min_size`                                                                                          |
| `name_prefix` (single field)                                     | `name` + `use_name_prefix = true`                                                                                                 |
| `disk_encrypted` / `disk_kms_key_id` / `disk_type` / `disk_size` | nested `block_device_mappings.xvda.ebs.{encrypted, kms_key_id, volume_type, volume_size}`                                         |
| `metadata_http_tokens` / `metadata_http_put_response_hop_limit`  | nested `metadata_options.{http_tokens, http_put_response_hop_limit}`                                                              |
| `kubelet_extra_args`                                             | `cloudinit_pre_nodeadm` NodeConfig with `spec.kubelet.config.systemReserved` (AL2023 — see [AL2023 migration](#al2023-migration)) |

`map_roles` and `map_users` are now folded into `access_entries`, keyed by
`username`, with `principal_arn` set to the role/user ARN and the original
`groups` translated to `kubernetes_groups`. RBAC bindings on the cluster that
key on the username string continue to work because the username is preserved
in the access-entry key.

### `modules/app_eks/outputs.tf`

| Output                               | Was                                                                                       | Now                                                          |
| ------------------------------------ | ----------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| `cluster_name`                       | `module.eks.cluster_id`                                                                   | `module.eks.cluster_name`                                    |
| `autoscaling_group_names`            | hand-rolled walk over `module.eks.node_groups[*].resources[0].autoscaling_groups[0].name` | `module.eks.eks_managed_node_groups_autoscaling_group_names` |
| `cluster_endpoint`                   | (not exposed — callers used `data "aws_eks_cluster"`)                                     | `module.eks.cluster_endpoint`                                |
| `cluster_certificate_authority_data` | (not exposed — callers used `data "aws_eks_cluster"`)                                     | `module.eks.cluster_certificate_authority_data`              |

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
must be worked around with a `merge()` or `local`-with-`null` pattern. The
current code uses a JSON round-trip (`jsondecode(... ? jsonencode({...}) :
"{}")`) so both branches type-unify as `string` at the ternary and `any` at
the module input — works on every Terraform 1.x.

### Security-group bridging

In v17, `worker_additional_security_group_ids` attached an _additional_ SG to
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
_siblings_ of `module.eks`. Nothing inside `module.eks` references them, so
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

- _Upgrading from v17 with the wandb-side OIDC provider already in state._
  Add `enable_irsa = false` and apply. The community module's
  `oidc_provider[0]` was never in your state, the wandb-side resource is
  unchanged, and there is nothing to import.
- _Bootstrapping a new cluster on v20 where the community module's resource
  already won the race and is in state_ (e.g. a `-target=module.eks` partial
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
_statically known_, Terraform refreshes the data source eagerly, and a
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

1. _Recommended._ Drop the `data "aws_eks_cluster"` data source entirely and
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

2. _Two-stage `-target` apply._ If you can't change the caller, run
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

### Preserving v17 resource names for true in-place upgrade (cluster + cluster IAM role + cluster SG)

A naive `terraform apply` against a v17-managed cluster, even with the `moved`
blocks in `modules/app_eks/moved.tf`, ends up with **5 forced replacements**
that ripple into a destroy/recreate of the EKS cluster's data plane:

| Resource                                                                       | What forces replacement                                                                                                                                                                         |
| ------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `module.eks.aws_iam_role.this[0]` (cluster role)                               | v17 used `name_prefix = var.cluster_name` (`"j7m4-foo"`); v20 default is `"${cluster_name}-cluster${prefix_separator}"` → `"j7m4-foo-cluster-"`. Different `name_prefix` ⇒ TF replaces.         |
| `module.eks.aws_eks_cluster.this[0]`                                           | Cascades from the IAM role replacement above (`role_arn` changes ⇒ `forces_replacement` on the cluster).                                                                                        |
| `module.eks.aws_security_group.cluster[0]`                                     | Same `name_prefix` story for the cluster SG, plus the v20 default `description` (`"EKS cluster security group"`) drops v17's trailing period. SG description is **immutable** in AWS ⇒ replace. |
| `module.eks.module.eks_managed_node_group["ng-N"].aws_eks_node_group.this[0]`  | v17's `node_group_name_prefix` was `"<namespace>-<az>"` (no trailing separator). v20 hardcodes `"${var.name}-"`.                                                                                |
| `module.eks.module.eks_managed_node_group["ng-N"].aws_launch_template.this[0]` | Same hardcoded `"${local.launch_template_name}-"` in the launch_template.                                                                                                                       |

The first three are fixable purely through inputs to the stock v20 community
module — that's what this branch does for the cluster, the cluster IAM role,
and the cluster SG. The last two are _not_ fixable without forking the
module; this branch accepts them, with the safety of v20's
`lifecycle.create_before_destroy = true` lifecycle on both — see
[Accepted replacement of node groups and launch templates](#accepted-replacement-of-node-groups-and-launch-templates)
below.

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

### Accepted replacement of node groups and launch templates

The remaining replacements come from two sources:

**1. Naming (v17 → v20 separator change).** The `eks-managed-node-group` submodule hardcodes a `"-"` separator:

```hcl
# stock terraform-aws-modules/eks/aws v20.37 modules/eks-managed-node-group/main.tf
name_prefix            = var.launch_template_use_name_prefix ? "${local.launch_template_name}-" : null
node_group_name_prefix = var.use_name_prefix ? "${var.name}-" : null
```

There is no input variable to override that `"-"`. The only way to keep the
v17 names is to fork the module and edit those two lines. **This branch does
not fork.**

**2. `ami_type` change (AL2 → AL2023).** This module now sets `ami_type =
"AL2023_x86_64_STANDARD"` on all node groups. `ami_type` is a `ForceNew`
attribute, so any node group whose existing `ami_type` differs (including
one where it was previously unset, which falls back to AL2) will be replaced.
See [AL2023 migration](#al2023-migration) for the full impact table.

Both sources apply on the v17 → v20 upgrade apply for AL2 clusters, but they
produce a **single** CBD replacement per node group — Terraform plans the
two ForceNew diffs together on the same resource. Instead, it accepts that:

- `module.eks.module.eks_managed_node_group["ng-N"].aws_launch_template.this[0]`
  is replaced.
- `module.eks.module.eks_managed_node_group["ng-N"].aws_eks_node_group.this[0]`
  is replaced.

What "replaced" means here is shaped by two things:

1. **`moved {}` blocks first.** The v17 state for each NG and LT is migrated
   from `module.eks.module.node_groups.aws_*.workers["ng-N"]` to the v20
   address `module.eks.module.eks_managed_node_group["ng-N"].aws_*.this[0]`
   via blocks in [`modules/app_eks/moved.tf`](../modules/app_eks/moved.tf).
   _Without_ the moves, v17's NG/LT state would be orphaned at the v17
   address, Terraform would destroy the orphan, and _separately_ create a
   new resource at the v20 address — no `create_before_destroy` linkage
   between the two operations, so the data plane would briefly drop to zero
   nodes. The moves preserve the state link, so what Terraform sees is
   "existing resource at this address, with `name_prefix` ForceNew drift" —
   a single replace operation where CBD applies.

2. **`lifecycle.create_before_destroy = true` in v20.** Both
   `aws_eks_node_group.this` (line ~477 in v20.37
   `modules/eks-managed-node-group/main.tf`) and `aws_launch_template.this`
   (line ~337) are declared with `create_before_destroy = true`. So at
   apply time:
   1. Terraform creates the _new_ `aws_launch_template` (with a new random
      suffix, e.g. `"j7m4-foo-a-<random>"` — note the `-` separator now).
   2. Terraform creates the _new_ `aws_eks_node_group` referencing the new
      LT. AWS spins up new EC2 instances on the new LT, kubelet registers,
      nodes go `Ready`, capacity is briefly doubled.
   3. Pods drain off the old NG via PodDisruptionBudgets — EKS managed node
      groups handle the cordon + drain automatically when the underlying
      `aws_eks_node_group` is being destroyed.
   4. Terraform destroys the _old_ `aws_eks_node_group` and the _old_
      `aws_launch_template`. The old EC2 instances terminate.

   Net result: capacity stays up throughout. Pods migrate via PDBs.
   Zero-downtime if PDBs are configured; brief disruption per pod-without-PDB
   during drain (same shape as a normal EKS node-version roll).

#### Operational impact in concrete terms

- **Wall-clock time**: ~10–15 minutes per AZ for the new NG to provision and
  go `Ready`, plus pod drain time (depends on PDBs and pod count). For a
  typical wandb deployment of 3 AZs with ~2 nodes each, the apply runs all
  3 NG replacements in parallel, so total wall-clock is ~15–20 minutes for
  the data-plane swap on top of the ~5 minutes of cluster/IAM/SG in-place
  updates.
- **Capacity**: briefly doubled. Make sure the AWS account has EC2 quota
  for the cluster's instance type at 2× steady-state across all AZs during
  the apply window.
- **Pods**: drained via PDB. Pods without a PDB get evicted with
  `terminationGracePeriodSeconds`. Stateful workloads with EBS-PVCs see the
  PVC detach from the old node and reattach to the new — same as a normal
  EKS node-version roll.
- **Cluster control plane**: not touched by this part of the apply. The
  cluster, its IAM role, its SG, its KMS key, its OIDC issuer, and the
  CloudWatch log group are all in-place updates only.
- **DNS / ingress**: ALB target groups re-register against the new node
  IPs automatically (ALB controller watches Service endpoints, which
  follow the new pods). Brief sub-second window per pod during the IP
  change.

#### Comparison to a Kubernetes minor-version bump

A Kubernetes minor-version bump (e.g. EKS 1.32 → 1.33) does **not** replace
the Terraform `aws_eks_node_group` or `aws_launch_template` resources — it
sets `aws_eks_node_group.version` in-place, EKS internally rolls EC2
instances onto a new AMI, and the TF resources stay in state. So the
module-bump apply on this branch causes one extra rolling node-roll
relative to a pure version bump. Operators planning to bump K8s minor
right after the module bump should expect:

- **Module-bump apply**: 1 graceful rolling node-roll (TF-driven, CBD).
- **Each subsequent K8s minor bump**: 1 graceful rolling node-roll
  (EKS-managed via `aws_eks_node_group.version` change).

The sibling branch `j7m4/v17to20varPrep` (with the vendored fork) buys
zero rolling node-rolls at the module-bump apply, at the cost of carrying
a fork of the v20 community module. Pick the branch that matches your
disruption budget.

### `kubelet_extra_args` → `cloudinit_pre_nodeadm` (AL2023)

In v17 the module rendered a launch-template user-data block that called
`bootstrap.sh --kubelet-extra-args "<value>"`. In v20 the AL2 equivalent was
`bootstrap_extra_args` on the node group defaults. **This branch has moved
past both.** All node groups are now pinned to `ami_type =
"AL2023_x86_64_STANDARD"` (see [AL2023 migration](#al2023-migration) below).
The `system_reserved_*` variable values are delivered to the kubelet via a
`cloudinit_pre_nodeadm` MIME part carrying a nodeadm `NodeConfig` fragment:

```yaml
---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  kubelet:
    config:
      systemReserved:
        cpu: "<system_reserved_cpu_millicores>m"
        memory: "<system_reserved_memory_megabytes>Mi"
```

`bootstrap_extra_args` has been removed from `eks_managed_node_group_defaults`
entirely. Setting it on AL2023 nodes would be a silent no-op — the AL2023
user-data path (`nodeadm`) does not invoke `bootstrap.sh`.

### AL2023 migration

This module now hardcodes `ami_type = "AL2023_x86_64_STANDARD"` in
`eks_managed_node_group_defaults`. Amazon Linux 2 reached end-of-life in
June 2025, and all supported EKS minor versions in this module (1.30–1.35)
default to AL2023 at the AWS API level.

**`ami_type` is a `ForceNew` attribute on `aws_eks_node_group`.** Changing
it — including the implicit change from "not set" (AL2 fallback) to
`AL2023_x86_64_STANDARD` — forces node group replacement. The replacement is
graceful: both the `aws_eks_node_group` and `aws_launch_template` resources
carry `lifecycle.create_before_destroy = true` in the community v20 module,
so AWS spins up AL2023 nodes before terminating the old AL2 nodes.

**Impact by scenario:**

| Starting state                                         | Impact of upgrading to this module version                                                                                                          |
| ------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| v17 on AL2 (default)                                   | Single graceful CBD replacement combining the v20 naming-change ForceNew _and_ the `ami_type` ForceNew. AL2023 nodes replace AL2 nodes in one roll. |
| v20 without `ami_type` set (AL2 fallback)              | Graceful CBD replacement due to `ami_type` change alone.                                                                                            |
| v20 with `ami_type = "AL2023_x86_64_STANDARD"` already | In-place update only. No node group replacement.                                                                                                    |

For the v17 → v20 upgrade path the AL2023 roll is folded into the
already-expected NG/LT replacement — operators see the same graceful CBD
swap described in
[Accepted replacement of node groups and launch templates](#accepted-replacement-of-node-groups-and-launch-templates),
but the new nodes come up with the AL2023 AMI rather than AL2.

**Capacity note.** The CBD discipline means AL2023 nodes come up _before_
AL2 nodes drain and terminate. EC2 quota and subnet IP headroom requirements
are identical to those described in step 4 of the
[upgrade runbook](#steps) — briefly 2× steady-state capacity per AZ.

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

All address renames are encoded as `moved {}` blocks in
[`modules/app_eks/moved.tf`](../modules/app_eks/moved.tf) — no manual
`terraform state mv` is required. The aws-auth ConfigMap adoption is in a
separate file ([`modules/app_eks/aws_auth_legacy.tf`](../modules/app_eks/aws_auth_legacy.tf))
and is gated by `var.preserve_aws_auth_configmap`.

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

- The `moved {}` blocks for the v17 → v20 address renames are in
  [`modules/app_eks/moved.tf`](../modules/app_eks/moved.tf).
- The aws-auth ConfigMap adoption is in
  [`modules/app_eks/aws_auth_legacy.tf`](../modules/app_eks/aws_auth_legacy.tf)
  (one more `moved {}` block plus a gated resource).
- The accepted NG/LT replacement (graceful via CBD) is documented in
  [Accepted replacement of node groups and launch templates](#accepted-replacement-of-node-groups-and-launch-templates).

### Sequencing relative to EKS version upgrades

This runbook covers **only the module upgrade** (community
`terraform-aws-modules/eks/aws` v17 → v20). If the same operator wants to
_also_ move the cluster to a newer Kubernetes minor (e.g. EKS 1.32 → 1.34),
they are three separate Terraform applies, in this order:

1. **Module v17 → v20, EKS version unchanged.** Follow this runbook end to
   end. `var.eks_cluster_version` does not change. The cluster's control
   plane is not touched by AWS — only resource-address moves, in-place
   attribute updates, v17-orphan cleanup, and the graceful NG/LT
   replacement described above. Validates the module migration in
   isolation.

2. **EKS minor bump #1 (e.g. 1.32 → 1.33), already on v20.** Flip
   `var.eks_cluster_version` (in the caller's tfvars) to the _next_ minor,
   re-plan, apply. The diff should be `aws_eks_cluster.this[0]` updating
   `version` in place plus a fresh `release_version` rolling on each
   `aws_eks_node_group.this[0]`. AWS upgrades the control plane first
   (~20–30 min), then EKS rolls each managed node group to a 1.33-compatible
   AMI. No NG/LT _resource_ replacement at this stage; only the EC2
   instances inside them roll.

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
  before reaching the cluster API. So the module must be on v20 _before_ the
  EKS version moves past what v17 supports.

You can interleave [step 10 of the runbook (retire the aws-auth ConfigMap)](#steps)
between any of these stages — it depends only on stage 1 completing and the
access-entry auth path being verified, not on any EKS version bump. The
recommended sequence is to retire aws-auth _after_ the EKS version moves are
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
     `terraform-aws-modules/eks/aws` version `~> 20.37`.
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
   - `cluster_endpoint` and `cluster_certificate_authority_data` re-exports
     in `outputs.tf` — see [Caller-side kubernetes/helm providers](#caller-side-kuberneteshelm-providers)
     for the caller-side wiring change that goes with these.

3. **Set the upgrade-only variables in your caller.** One flag is needed
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

4. **Pre-flight capacity check.** The graceful NG/LT replacement
   (see [Accepted replacement of node groups and launch templates](#accepted-replacement-of-node-groups-and-launch-templates))
   briefly doubles EC2 capacity per AZ during apply. Verify:
   - **EC2 quota.** For each AZ's instance type, current usage + same-again
     should not exceed the EC2 service quota. For default `m5.large` and 2
     nodes per AZ across 3 AZs, that's 12 instances peak vs 6 steady-state.
     Check via `aws service-quotas get-service-quota --service-code ec2
--quota-code <relevant>`.
   - **Subnet IP capacity.** Each new node consumes one ENI's worth of IPs
     (plus pod-level secondary IPs for VPC-CNI). Confirm each private
     subnet has 2× steady-state headroom. `aws ec2 describe-subnets
--filters Name=vpc-id,Values=<vpc-id> --query 'Subnets[*].
{Subnet:SubnetId,Available:AvailableIpAddressCount}'`.
   - **PodDisruptionBudgets.** Workloads that should not see eviction
     beyond N concurrent unavailable should have a PDB declaring that.
     The drain phase honors PDBs.

5. **`terraform init -upgrade`.** Picks up the new module version, the v5
   AWS provider, and any new module-level providers v20 declares.

   ```bash
   terraform init -upgrade
   ```

6. **First plan and read it carefully.**

   ```bash
   terraform plan -no-color > /tmp/v20-stage1.txt
   ```

   Expected diff:
   - **In-place updates** for the cluster, cluster IAM role, cluster SG,
     CloudWatch log group. The cluster's update is tag-only; the IAM role's
     adds `sts:TagSession` to its assume-role policy; the rest are tag
     updates and minor field normalization. **None should be marked
     `forces replacement`.**
   - **`aws_eks_cluster.this[0]` must NOT be `must be replaced`.** If it
     is, the most common cause is a missed name override in step 2 — the
     cluster IAM role gets a different `name_prefix` and TF treats it as a
     different resource, which cascades to a cluster recreate. Re-read the
     `iam_role_name` / `prefix_separator` lines in `modules/app_eks/main.tf`
     before continuing.
   - **`aws_iam_role.this[0]` and `aws_security_group.cluster[0]` must NOT
     be `must be replaced`** either. They each share a `name_prefix` knob
     with the cluster; if either shows replacement, the corresponding
     override (see step 2) is missing.
   - **Expected replacements (graceful via CBD)**: `aws_eks_node_group.this[0]`
     and `aws_launch_template.this[0]` for _each_ node group key. For a
     standard 3-AZ deployment that's 6 forced replacements total. Each
     pair lands as a CBD swap at apply time — see
     [Accepted replacement of node groups and launch templates](#accepted-replacement-of-node-groups-and-launch-templates).
     In the plan output these show as `# (must be replaced)` with
     `created_before_destroy = true`.
   - **Renames** ("have moved") for everything in
     [`modules/app_eks/moved.tf`](../modules/app_eks/moved.tf): cluster IAM
     role, its `AmazonEKSClusterPolicy` attachment, the cluster SG ingress
     rule, all node groups, all launch templates. Also from
     [`modules/app_eks/aws_auth_legacy.tf`](../modules/app_eks/aws_auth_legacy.tf):
     the `kube-system/aws-auth` ConfigMap from `module.eks.kubernetes_config_map.aws_auth[0]`
     to `kubernetes_config_map.aws_auth_legacy[0]`. The NG/LT moves don't
     prevent the replacement above, but they keep state attached to the
     v20 address so CBD can run.
   - **One acceptable extra replacement**:
     `aws_security_group_rule.cluster["ingress_nodes_443"]` (because its
     `source_security_group_id` migrates from the v17 worker SG to the v20
     node SG). Sub-second gap during apply; pods continue running because
     the rule governs new auth handshakes, not in-flight kubelet sessions.
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
     `aws_security_group.node[0]` and its 11 rules, `time_sleep.this[0]`,
     `aws_iam_policy.cluster_encryption[0]` (only when `var.kms_key_arn != ""`),
     `aws_iam_policy.custom[0]`, four `aws_ec2_tag.cluster_primary_security_group[*]`
     entries, and per-NG `module.user_data.null_resource.validate_cluster_service_cidr`.
     `aws_eks_access_entry.this["cluster_creator"]` and its
     `aws_eks_access_policy_association` should _not_ appear — this branch
     sets `enable_cluster_creator_admin_permissions = false` so that AWS
     owns the cluster-creator entry implicitly. If you see them in the
     plan, the flag has been flipped back to `true` and the apply will hit
     the 409 race documented in step 8 below.
   - **No KMS create.** `module.eks.module.kms.aws_kms_key.this[0]` should
     not appear; if it does, `create_kms_key = false` isn't taking effect or
     `var.kms_key_arn` was inadvertently changed.

   Stop and diagnose if your plan shows replacements on `aws_eks_cluster`,
   `aws_iam_role.this`, `aws_security_group.cluster`, the KMS key, or the
   wandb-side OIDC provider — those would be unrecoverable in a single
   apply and indicate a configuration error.

7. **Hand-check the destroys.** Confirm the destroyed worker IAM role
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

8. **Apply, monitoring the data plane.**

   ```bash
   terraform apply
   ```

   Optional: stage the apply with two `-target` flags first for a checkpoint
   after the cluster/role/SG state moves and in-place updates land but
   before the helm releases reconcile against the v20 module addresses:

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
   block.

   **In a separate terminal during the apply**, watch the data plane:

   ```bash
   # Watch nodes — should see new ones come up, then old ones drain & terminate.
   watch -n 5 'kubectl get nodes -o wide --sort-by=.metadata.creationTimestamp'

   # Watch evictions — confirms PDBs are honoring drains.
   kubectl get events -A --field-selector reason=Evicted -w

   # HTTPS endpoint should stay up throughout.
   while true; do curl -sSI -o /dev/null -w "%{http_code} %{time_total}s\n" \
     https://<your-fqdn>/; sleep 5; done
   ```

   Watch for:
   - **`ResourceInUseException` (HTTP 409) on `aws_eks_access_entry.this["cluster_creator"]`.**
     This branch sets `enable_cluster_creator_admin_permissions = false`
     (see `modules/app_eks/main.tf`) to prevent the race described below, so
     under normal usage you should _not_ see this error. If you do, it means
     someone has either flipped that flag back to `true` or duplicated the
     cluster-creator's ARN in `map_roles` / `map_users` — fix that and
     re-apply, or use the fallback import recipe further down.

     _Why the flag is false._ When `authentication_mode` includes `"API"`,
     AWS auto-creates an access entry (with `AmazonEKSClusterAdminPolicy`
     attached) for the IAM principal that created the cluster. v20's
     `enable_cluster_creator_admin_permissions = true` would have TF try to
     create the same entry — AWS wins the race, TF 409s. Setting the flag
     to `false` lets AWS own that single entry (admin behavior unchanged);
     all _named_ admins still flow through `map_roles` / `map_users` →
     `access_entries` and stay TF-managed.

     _Trade-off._ The cluster-creator entry is AWS-managed, not TF-managed.
     `terraform plan` won't show it, and revoking it requires the AWS
     console or `aws eks delete-access-entry` rather than a TF diff. AWS
     deletes it automatically when the cluster is destroyed.

     _Fallback (only if a caller insists on TF-managing the cluster-creator
     entry)._ Set `enable_cluster_creator_admin_permissions = true` and
     accept the 409 on first apply, then import AWS's auto-created entry
     and its policy association before re-running:

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

     The principal ARN is the IAM role of whoever ran the _original_ v17
     `terraform apply` that created the cluster; for an SSO setup it looks
     like the example above. AWS also auto-creates an access entry for the
     wandb-side `aws_iam_role.node` and for `AWSServiceRoleForAmazonEKS` —
     those are not in TF's plan and don't need importing.

   - **`NodeCreationFailure`** on any node group rolling its launch template —
     see [Node IAM role](#node-iam-role) for the IAM-attachment race that can
     manifest if a partial apply was used.
   - **Stuck pod evictions** during the NG/LT replacement. If a PDB is too
     restrictive (e.g. `minAvailable: 100%`), the drain blocks indefinitely
     and the apply hangs on `aws_eks_node_group.this[0]: Still destroying...`
     for hours. Resolution: relax the PDB temporarily (`kubectl edit pdb
-n <ns> <name>`) so drain can complete, or accept a forceful eviction
     once the new NG has demonstrated it can host the workload.
   - **`OptInRequired`** or other access-entry errors that aren't 409s —
     these mean the cluster's `authentication_mode` flip didn't land yet;
     run the apply again.

9. **Re-plan to confirm convergence.** Immediately after the apply:

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

10. **Sanity-check the data plane.**

    ```bash
    kubectl get nodes
    kubectl -n kube-system get pods
    kubectl auth can-i --list --as <a-mapped-role-arn>   # access-entry sanity
    aws eks describe-cluster --name <namespace> \
      --query 'cluster.{Status:status,Version:version,RoleArn:roleArn}'
    ```

    Verify:
    - All nodes are `Ready` and have AGE consistent with the apply window
      (NOT older — old nodes should have been replaced).
    - The cluster `RoleArn` matches the v17-era ARN you snapshotted in
      step 1. If it changed, something replaced the cluster — stop and
      diagnose before doing anything else.
    - No pods stuck in `Evicted` / `Pending`. `kubectl get pods -A | grep
-vE 'Running|Completed'` should be empty.

    The full data-plane bridge check (pods can reach RDS / ElastiCache / ALB)
    is in the [Verification checklist](#verification-checklist).

11. **Retire the aws-auth ConfigMap (separate apply).** Once the access-entry
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
    hour) between step 8 and step 11. If anything was still relying on
    aws-auth, that's when you'll see it — and you can flip the variable back
    to `true` and reapply to recover.

### Rollback

If step 8 fails halfway and you need to roll back to v17, the safe path is:

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

After that, `terraform plan` under v17 should be empty.

#### Failure modes during apply, ranked

The graceful CBD swap on the NG/LT replacement bounds the blast radius of
mid-apply failure to "the new NG never goes Ready," in which case the old
NG is still up and serving traffic. From most-recoverable to
least-recoverable:

1. **Apply fails before any NG/LT replacement starts.** Cluster, IAM role,
   and SG are in-place updates only and TF dependency-orders them first.
   If an unrelated error stops the apply here (e.g. a transient AWS API
   error, or — if `enable_cluster_creator_admin_permissions` was flipped
   back to `true` — the `cluster_creator` 409), the data plane is
   untouched. Re-run `terraform apply` and resume.
2. **Apply fails during the new NG creation.** The new NG never registers
   nodes. The old NG is still up. TF's CBD discipline means it won't tear
   down the old NG until the new one is healthy, so the data plane keeps
   serving. Diagnose the new NG's failure (often: subnet capacity,
   instance-type quota, or the IAM-attachments race in
   [Node IAM role](#node-iam-role)), correct, re-apply.
3. **Apply fails during pod drain off the old NG.** The new NG is healthy
   and serving. The old NG is cordoned. A PDB is blocking drain. Pods are
   running on a mix of old + new nodes. Resolution: relax the offending
   PDB, re-apply; TF resumes by destroying the old NG.
4. **Apply fails during the v17-orphan destroys.** These are the last
   sequence in the apply, after the NG/LT swap and the cluster updates
   have already landed. The cluster is on v20, the data plane is healthy.
   Whatever failed (e.g. an IAM dependency that wasn't fully detached)
   can be diagnosed at leisure and re-applied; the user-facing system is
   already up on v20.

The case the prep-branch (vendored fork) variant strictly avoids — a
mid-apply state where the NG/LT have been _replaced_ but the data plane
hasn't caught up — is bounded here by CBD. If you need stricter avoidance
than CBD provides, use the prep-branch variant.

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

1. _Enumerate explicit principals._ Add the specific roles/users from the
   trusted account to `kubernetes_map_roles` / `kubernetes_map_users` —
   these now flow into `access_entries`. This is the right answer for
   almost everyone.

2. _Manage the ConfigMap directly as a stopgap._ `authentication_mode =
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

## Expected plan output

The runbook in this document targets the following per-stage shape. Numbers
will vary slightly with the number of node groups (one per private subnet),
the presence/absence of optional features (`var.create_elasticache`,
`var.private_link_allowed_account_ids`), and whether `var.kms_key_arn` is
set.

### Stage 1 — module v17 → v20, EKS K8s version unchanged

|                                                        |                                                                                                                                       |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------- |
| Cluster `aws_eks_cluster.this[0]`                      | **in-place update** (tags only)                                                                                                       |
| Cluster IAM role `aws_iam_role.this[0]`                | **in-place update** (`sts:TagSession` added to assume-role policy)                                                                    |
| Cluster SG `aws_security_group.cluster[0]`             | **in-place update** (tags only)                                                                                                       |
| Each `aws_eks_node_group.this[0]`                      | **REPLACED** (graceful via `create_before_destroy`; caused by v20 naming-change ForceNew and `ami_type` AL2→AL2023 ForceNew combined) |
| Each `aws_launch_template.this[0]`                     | **REPLACED** (graceful via `create_before_destroy`)                                                                                   |
| `aws_security_group_rule.cluster["ingress_nodes_443"]` | **REPLACED** (source SG migrates from v17 worker SG to v20 node SG; sub-second gap)                                                   |
| `kubernetes_config_map.aws_auth_legacy[0]`             | **in-place update via `moved {}` adoption** (label cleanup; data preserved via `lifecycle.ignore_changes`)                            |

Plan headline shape: roughly `25-30 to add, 7-10 to change, 15-20 to destroy`,
with `must be replaced` count = `2 × (number of NGs) + 1`. For a 3-AZ
deployment with one NG per AZ, expect 7 forced replacements (6 NG/LT pairs

- 1 ingress-rule). For a 2-AZ deployment, 5.

### Stage 2 / Stage 3 — EKS K8s minor bump (e.g. 1.32 → 1.33 → 1.34)

|                                   |                                                                                                                        |
| --------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `aws_eks_cluster.this[0]`         | **in-place version update**                                                                                            |
| Each `aws_eks_node_group.this[0]` | **in-place update** (AWS rolls AMIs, ~5–8m per NG, parallel across AZs)                                                |
| `module.eks.time_sleep.this[0]`   | **REPLACED** (TF-internal helper; trigger is the cluster_version string; harmless)                                     |
| Add-ons                           | **in-place version updates** auto-resolved to next-minor-compatible versions via `data "aws_eks_addon_version"` blocks |

Plan headline shape: `1 to add, 8-10 to change, 1 to destroy`, 1 forced
replacement (the `time_sleep` only). Total apply duration: ~12–18 minutes
(control plane upgrade + parallel NG rolls).

### Stage 4 — retire the aws-auth ConfigMap

|                                            |             |
| ------------------------------------------ | ----------- |
| `kubernetes_config_map.aws_auth_legacy[0]` | **destroy** |

Plan headline: `0 to add, 0 to change, 1 to destroy`. No data-plane impact —
nodes don't roll, pods don't migrate.

## Verification checklist

- [ ] `terraform init -upgrade` succeeds.
- [ ] `terraform validate` passes for the module and every example under
      `examples/`.
- [ ] `terraform plan` against an existing v17-managed cluster shows the
      entire `module.app_eks.module.eks.*` tree as moved (via `moved` blocks)
      _or_ replaced (NG/LT pair) with `created_before_destroy = true`,
      not destroyed/recreated without the CBD discipline.
- [ ] `terraform plan` against a cluster previously applied with v17 of the
      module shows **no** `must be replaced` for `aws_eks_cluster.this[0]`,
      `aws_iam_role.this[0]`, `aws_security_group.cluster[0]`, or the wandb-side
      `aws_iam_openid_connect_provider.eks`. Replacements should be limited
      to `aws_eks_node_group.this[0]`, `aws_launch_template.this[0]`,
      `aws_security_group_rule.cluster["ingress_nodes_443"]`, and
      `module.eks.time_sleep.this[0]`.
- [ ] On a freshly created cluster, the cluster-creator principal has
      `AmazonEKSClusterAdminPolicy` via the AWS-auto-created access entry
      (`aws eks list-associated-access-policies --cluster-name <namespace>
    --principal-arn <creator-arn>`), and `map_roles` / `map_users` are
      represented one-to-one as TF-managed `access_entries`.
- [ ] Pods on the new node groups can reach RDS, ElastiCache, and the ALB —
      proves the `primary_workers` SG bridging is wired correctly.
- [ ] All nodes are AL2023 (`kubectl get nodes -o jsonpath='{.items[*].status.nodeInfo.osImage}'`
      should show `Amazon Linux 2023`). This module mandates
      `ami_type = "AL2023_x86_64_STANDARD"` — AL2 nodes after a successful
      upgrade apply indicate the CBD replacement did not complete.
- [ ] On AL2023 nodes, `kubectl get --raw
    /api/v1/nodes/<node>/proxy/configz` shows the configured
      `systemReserved` values under `kubeletconfig.systemReserved`. These are
      delivered via `cloudinit_pre_nodeadm` / nodeadm, not `bootstrap_extra_args`.
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
- [ ] **NG/LT swap was graceful.** During the upgrade apply, `kubectl get
    nodes -o wide` showed both old and new nodes coexisting briefly (new
      nodes Ready before old nodes terminated). HTTPS endpoint to the ALB
      returned 200 throughout. No pods reported `OutOfPods`, `Evicted`, or
      stuck `Pending`.
- [ ] **Cluster identity preserved.** `aws eks describe-cluster --name
    <namespace>` returned the same `roleArn`, `endpoint`,
      `identity.oidc.issuer`, and `arn` as the v17-era values from the
      pre-upgrade state snapshot.
- [ ] First `terraform plan` after step 5 (init) of the upgrade runbook
      shows `kubernetes_config_map.aws_auth_legacy[0] will be updated in-place`
      (moved from `module.eks.kubernetes_config_map.aws_auth[0]`), **not**
      `kubernetes_config_map.aws_auth[0] will be destroyed`. Proves
      `var.preserve_aws_auth_configmap = true` is in effect and the moved
      block in `modules/app_eks/aws_auth_legacy.tf` is doing its job.
- [ ] After step 11 (`preserve_aws_auth_configmap = false` and apply), the
      cluster's kube-system/aws-auth ConfigMap is gone (`kubectl -n kube-system
    get configmap aws-auth` returns NotFound), and access entries are the
      sole auth path. Run for at least one kubelet credential rotation
      (~1 hour) before considering the migration complete.
