# wandb fork notes for the vendored `terraform-aws-modules/eks/aws` v20.37

This directory is a vendored copy of the upstream community module at tag
v20.37.x, with three small additive patches applied to support a true
in-place upgrade from the v17.x line of the same module without forcing
the EKS cluster, IAM role, security group, node groups, or launch
templates to be replaced. The upstream `README.md` is unchanged — read it
first if you want to understand the module surface; this file documents
*only* the wandb-side patches.

The full rationale, the resource-by-resource diff, and the operator
runbook that depends on these patches all live in
[`../../docs/upgrade-eks-20.md`](../../docs/upgrade-eks-20.md), specifically
the section
[Preserving v17 resource names for true in-place upgrade](../../docs/upgrade-eks-20.md#preserving-v17-resource-names-for-true-in-place-upgrade).

## What's patched

All three patches surround the same idea: v17 named the launch template and
node group with `name_prefix = "<namespace>-<az>"` (no trailing separator);
stock v20 hardcodes `"${name}-"` (with trailing dash). The trailing dash
forces TF to treat the v17 resources as different and replace them, which
takes the data plane down. The patches make the separator configurable via
a new `name_prefix_separator` variable that defaults to `"-"` — so stock
callers behave identically — and lets wandb-side configuration pass `""` to
preserve v17's naming.

| File | Change |
| --- | --- |
| `modules/eks-managed-node-group/variables.tf` | Appends the new `variable "name_prefix_separator"` (default `"-"`). |
| `modules/eks-managed-node-group/main.tf` | Replaces two literal `"-"`s on `aws_launch_template.this.name_prefix` and `aws_eks_node_group.this.node_group_name_prefix` with `${var.name_prefix_separator}`. |
| `node_groups.tf` | Forwards `name_prefix_separator = try(each.value.name_prefix_separator, var.eks_managed_node_group_defaults.name_prefix_separator, "-")` from the parent `module "eks"` invocation into `module "eks_managed_node_group"`. |

## How wandb opts in

In `modules/app_eks/main.tf`, the `module "eks"` invocation:

- Sources from this vendored copy: `source = "../../vendored/terraform-aws-eks-v20"`.
- Sets `eks_managed_node_group_defaults.name_prefix_separator = ""`.
- Pins each entry's `launch_template_name = "${var.namespace}-${az}"` (otherwise
  the parent module defaults the launch_template_name to `each.key`, e.g.
  `"ng-0"`, which still doesn't match v17's pattern even with the separator
  override).

## Upstream-PR posture

The patches are additive (default value `"-"` preserves existing behavior
for every other consumer of the module) and would be a reasonable upstream
PR to `terraform-aws-modules/eks/aws`. The wandb fork lives here only so
the in-place upgrade is reproducible without waiting on upstream to merge.

## Updating the vendored copy

When upstream releases a new patch version worth picking up, refresh this
directory by re-syncing from the registry copy and re-applying the three
patches above. The patch surface is small enough that a manual `diff -u`
against the new upstream is the cleanest path; nothing here deviates from
upstream beyond what's listed in the table.
