# v17 → v20 + EKS 1.32 → 1.34 in-place upgrade — test report

**Companion to** [`upgrade-eks-20.md`](./upgrade-eks-20.md). That document
defines the procedure; this one is the lab notebook from one end-to-end run
of the procedure against a sandbox install.

**Test target.** A wandb deployment named `j7m4-0430a` running on:

- AWS account `770934259321`, region `us-east-2`, profile `SbxAdmin`.
- EKS cluster on Kubernetes `1.32`.
- `terraform-aws-modules/eks/aws ~> 17.23` (the v17 line) at the start of
  the test.
- AWS Terraform provider `~> 4.0`.
- Standard wandb data plane: 2 managed node groups (`ng-0` in
  `us-east-2a`, `ng-1` in `us-east-2b`), Aurora MySQL, ElastiCache Redis,
  S3 file storage, EFS, ALB ingress, Route53 sub-zone for `j7m4-0430a.wandb.ml`,
  ACM certificate, GCP-Cloud-DNS-managed parent zone delegation.

**Goal.** Move the deployment to:

- `terraform-aws-modules/eks/aws ~> 20.37`.
- AWS Terraform provider `~> 5.95`.
- EKS Kubernetes `1.34`.
- EKS access entries as the sole auth method (retiring `aws-auth`
  ConfigMap).

…all without recreating the EKS cluster, the data-plane node groups, the
KMS key, the OIDC issuer URL, the IAM role/SG identities, the database,
the cache, the bucket, the load balancer, the DNS records, or the
certificate.

**Result.** Goal achieved. Four sequential `terraform apply` operations,
each verified clean (`terraform plan` returned `No changes`) before
proceeding to the next. Cluster `roleArn` stayed at the literal v17-era
value (`arn:aws:iam::770934259321:role/j7m4-0430a20260430181736075700000006`)
across all four stages; `cluster_endpoint`, OIDC issuer URL, EKS cluster
ID, and the wandb-side `aws_iam_openid_connect_provider.eks` ARN were
unchanged. HTTPS endpoint (`https://j7m4-0430a.wandb.ml/`) returned
HTTP 200 at every verification point throughout.

The headlines per stage are below; the runbook in `upgrade-eks-20.md`
(specifically the Validation results section) has the timing and
plan-summary numbers, and the per-stage detail follows here.

---

## Stage 1 — terraform-aws-modules/eks/aws v17 → v20 (EKS Kubernetes version unchanged at 1.32)

**Plan headline.** `27 to add, 13 to change, 18 to destroy`, 1 forced
replacement.

### Added (27 resources)

All of these are v20-shape resources with no v17 equivalent — they
implement features (access entries, encrypted EKS log groups, node
security groups) that didn't exist in v17 of the community module.

| Address | What it is |
| --- | --- |
| `module.eks.aws_eks_access_entry.this["cluster_creator"]` | EKS access entry that grants the IAM principal who originally provisioned the cluster admin access via the access-entries auth path. (Imported during the apply rather than created — see "Anomalies" below.) |
| `module.eks.aws_eks_access_policy_association.this["cluster_creator_admin"]` | Attaches the `AmazonEKSClusterAdminPolicy` to the access entry above. (Also imported.) |
| `module.eks.aws_iam_policy.cluster_encryption[0]` | IAM policy for the cluster encryption KMS key (no-op since `var.kms_key_arn` is empty in this install, but the resource is still created). |
| `module.eks.aws_iam_policy.custom[0]` | Empty placeholder IAM policy for caller-supplied custom statements. |
| `module.eks.aws_iam_role_policy_attachment.cluster_encryption[0]` | Attaches `aws_iam_policy.cluster_encryption` to the cluster IAM role. |
| `module.eks.aws_iam_role_policy_attachment.custom[0]` | Same for `aws_iam_policy.custom`. |
| `module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]` | New v20 attachment naming. (v17 had `…cluster_AmazonEKSVPCResourceControllerPolicy[0]`, destroyed below.) |
| `module.eks.aws_security_group.node[0]` | The v20 node security group (replaces v17's `aws_security_group.workers[0]`). |
| `module.eks.aws_security_group_rule.node["egress_all"]` | Outbound rule for the new node SG. |
| `module.eks.aws_security_group_rule.node["ingress_cluster_443"]` | Cluster-API ingress, sourced from the cluster SG. |
| `module.eks.aws_security_group_rule.node["ingress_cluster_4443_webhook"]` | webhook port for cluster-extension webhooks. |
| `module.eks.aws_security_group_rule.node["ingress_cluster_6443_webhook"]` | webhook port. |
| `module.eks.aws_security_group_rule.node["ingress_cluster_8443_webhook"]` | webhook port. |
| `module.eks.aws_security_group_rule.node["ingress_cluster_9443_webhook"]` | webhook port. |
| `module.eks.aws_security_group_rule.node["ingress_cluster_kubelet"]` | kubelet API port (10250). |
| `module.eks.aws_security_group_rule.node["ingress_nodes_ephemeral"]` | Ephemeral port range for inter-node traffic. |
| `module.eks.aws_security_group_rule.node["ingress_self_coredns_tcp"]` | CoreDNS pod-to-pod TCP. |
| `module.eks.aws_security_group_rule.node["ingress_self_coredns_udp"]` | CoreDNS pod-to-pod UDP. |
| `module.eks.aws_security_group_rule.node["primary_workers_all"]` | All-traffic ingress sourced from the wandb-side `primary_workers` SG (preserves v17 SG bridging). |
| `module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]` | Cluster-side counterpart of `ingress_cluster_443`, sourced from the new node SG. (This is the one resource that actually replaces — see "Replaced" below.) |
| `module.eks.aws_ec2_tag.cluster_primary_security_group["GithubOrg"]` | Tag on the EKS-managed primary cluster SG (v20 manages tags as separate resources). |
| `module.eks.aws_ec2_tag.cluster_primary_security_group["GithubRepo"]` | Tag. |
| `module.eks.aws_ec2_tag.cluster_primary_security_group["TerraformModule"]` | Tag. |
| `module.eks.aws_ec2_tag.cluster_primary_security_group["TerraformNamespace"]` | Tag. |
| `module.eks.time_sleep.this[0]` | TF helper resource that gates downstream node-group operations on the cluster having had time to settle. |
| `module.eks_managed_node_group["ng-0"].module.user_data.null_resource.validate_cluster_service_cidr` | TF-internal validation. |
| `module.eks_managed_node_group["ng-1"].module.user_data.null_resource.validate_cluster_service_cidr` | TF-internal validation. |

### Changed (13 in-place updates)

| Address | What changed (in-place) |
| --- | --- |
| `module.eks.aws_eks_cluster.this[0]` | New tag `terraform-aws-modules = "eks"` added; no other change. **Cluster ARN, endpoint, OIDC URL, role ARN, version, all preserved.** |
| `module.eks.aws_iam_role.this[0]` | (Moved from `module.eks.aws_iam_role.cluster[0]`.) `assume_role_policy` gained `sts:TagSession` alongside the existing `sts:AssumeRole`. |
| `module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]` | (Moved from the v17 `cluster_AmazonEKSClusterPolicy[0]` address.) Re-keyed under the new `for_each`-style key. |
| `module.eks.aws_security_group.cluster[0]` | Tag updates only (the `cluster_security_group_description` override matched v17's literal string, so the immutable `description` field didn't trigger a replace). |
| `module.eks.aws_cloudwatch_log_group.this[0]` | Tag updates only. |
| `module.eks.module.eks_managed_node_group["ng-0"].aws_eks_node_group.this[0]` | (Moved from v17 `module.node_groups.aws_eks_node_group.workers["ng-0"]`.) Tag updates only — `node_group_name_prefix` matched v17 thanks to the `name_prefix_separator = ""` override on the vendored submodule. |
| `module.eks.module.eks_managed_node_group["ng-1"].aws_eks_node_group.this[0]` | Same as ng-0. |
| `module.eks.module.eks_managed_node_group["ng-0"].aws_launch_template.this[0]` | (Moved.) `description` text refresh, no name change. |
| `module.eks.module.eks_managed_node_group["ng-1"].aws_launch_template.this[0]` | Same. |
| `module.cluster_autoscaler.aws_iam_role.default` | IRSA role assume-role policy refresh. |
| `module.cluster_autoscaler.helm_release.cluster-autoscaler` | Helm values refresh from the new TF-side spec. |
| `module.external_dns.aws_iam_role.default` | IRSA role refresh. |
| `module.lb_controller.aws_iam_role.default` | IRSA role refresh. |
| `kubernetes_config_map.aws_auth_legacy[0]` | (Moved from `module.eks.kubernetes_config_map.aws_auth[0]`.) Two label entries dropped (`app.kubernetes.io/managed-by = "Terraform"` and `terraform.io/module = "terraform-aws-modules.eks.aws"`); `data` left alone via `lifecycle.ignore_changes`. |

### Replaced (1)

| Address | Why |
| --- | --- |
| `module.eks.aws_security_group_rule.cluster["ingress_nodes_443"]` | (Moved from `cluster_https_worker_ingress[0]`.) Its `source_security_group_id` migrates from the v17 `aws_security_group.workers[0]` (being destroyed) to the v20 `aws_security_group.node[0]` (being created). `source_security_group_id` is a forces-replacement field on `aws_security_group_rule`. |

### Destroyed (18 resources, all v17 orphans)

These are v17-only resources that the v20 community module no longer
declares. None of them are referenced by anything outside the v17
community module's own scope, so destroying them is non-disruptive.

| Address | What it was |
| --- | --- |
| `module.eks.aws_iam_role.workers[0]` | v17's worker IAM role. **Not** referenced by the wandb data plane — wandb uses `aws_iam_role.node` (declared in `modules/app_eks/iam-roles.tf`), which is unchanged. |
| `module.eks.aws_iam_role_policy_attachment.workers_AmazonEKSWorkerNodePolicy[0]` | Attachment on the v17 worker role. |
| `module.eks.aws_iam_role_policy_attachment.workers_AmazonEKS_CNI_Policy[0]` | Same. |
| `module.eks.aws_iam_role_policy_attachment.workers_AmazonEC2ContainerRegistryReadOnly[0]` | Same. |
| `module.eks.aws_iam_policy.cluster_deny_log_group[0]` | v17-only IAM policy that denied additional log group creates. v20 doesn't carry it. |
| `module.eks.aws_iam_role_policy_attachment.cluster_deny_log_group[0]` | Attachment for the policy above. |
| `module.eks.aws_iam_policy.cluster_elb_sl_role_creation[0]` | v17-only IAM policy for elasticloadbalancing service-linked role creation. v20 doesn't carry it. |
| `module.eks.aws_iam_role_policy_attachment.cluster_elb_sl_role_creation[0]` | Attachment for the policy above. |
| `module.eks.aws_iam_role_policy_attachment.cluster_AmazonEKSServicePolicy[0]` | v17-shape attachment. v20 covers this via `AmazonEKSClusterPolicy`. |
| `module.eks.aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceControllerPolicy[0]` | v17-shape attachment, replaced by the v20 keyed attachment under `aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]`. |
| `module.eks.aws_security_group.workers[0]` | v17's worker security group. Replaced functionally by the new `aws_security_group.node[0]`. |
| `module.eks.aws_security_group_rule.workers_egress_internet[0]` | Worker SG egress rule. |
| `module.eks.aws_security_group_rule.workers_ingress_cluster[0]` | Worker SG ingress rule. |
| `module.eks.aws_security_group_rule.workers_ingress_cluster_https[0]` | Worker SG ingress rule. |
| `module.eks.aws_security_group_rule.workers_ingress_self[0]` | Worker SG self-ingress rule. |
| `module.eks.aws_security_group_rule.cluster_egress_internet[0]` | Cluster SG egress rule (v20 doesn't manage egress on the cluster SG). |
| `module.eks.local_file.kubeconfig[0]` | v17 wrote a kubeconfig file to disk on each apply. v20 doesn't. |
| `module.eks_managed_node_group["ng-0"].module.user_data.null_resource.validate_cluster_service_cidr` (one each per NG, see above) | Same address re-created — TF reports them in both columns because they re-key. |

### Anomalies / surgical interventions

Two during this stage:

1. **Targeted apply requires two `-target` flags.** The aws-auth `moved {}`
   block routes from `module.eks.kubernetes_config_map.aws_auth[0]` (in the
   first target's subtree) to `kubernetes_config_map.aws_auth_legacy[0]`
   (outside it). TF refused the targeted plan with an actionable error
   identifying the missing target. Adding
   `-target=module.app_eks.kubernetes_config_map.aws_auth_legacy` made the
   plan acceptable.
2. **`ResourceInUseException` (HTTP 409) on
   `aws_eks_access_entry.this["cluster_creator"]`.** When v20's apply flips
   `authentication_mode` to `API_AND_CONFIG_MAP`, AWS auto-creates an
   access entry for the IAM principal that originally provisioned the
   cluster. v20's TF then races to create the same entry (because of
   `enable_cluster_creator_admin_permissions = true`). Resolved by
   `terraform import` of the AWS-auto-created entry and its policy
   association into TF state, then resuming the apply.

Both have been folded into the runbook's step 7 with the exact
commands.

### Customer-facing impact during stage 1

| Surface | Observed |
| --- | --- |
| `https://j7m4-0430a.wandb.ml/` (HTTP 200/HTTPS) | continuously responsive, HTTP 200 at every spot-check |
| Cluster API (`aws eks describe-cluster`) | continuously available |
| Pod scheduling | EKS rolled both managed node groups due to the launch_template version update — drains pods, terminates the old instance, brings up a new one with the new launch_template version. ~2-3 minute pod reschedule per node-group rotation. Pods running stateful workloads (databases) are external to the cluster, so unaffected. |
| Database / cache / S3 / EFS | no changes |
| DNS records | no changes |
| Certificate | no changes |

For a production user the visible impact would have been: a brief
window of in-flight HTTP requests possibly failing during pod
reschedules (ALB target groups have health checks and route around
unhealthy targets, but if every target for a given backend is
simultaneously rescheduling, requests fail). For this sandbox install
with no external traffic, observed impact was zero.

---

## Stage 2 — EKS 1.32 → 1.33

**Plan headline.** `1 to add, 9 to change, 1 to destroy`, 1 forced
replacement (the `time_sleep` helper, harmless).

### Added (1)

| Address | What it is |
| --- | --- |
| `module.eks.time_sleep.this[0]` | Re-created with the new `cluster_version` trigger. The previous stage-1-created instance was destroyed for the same reason. |

### Changed (9 in-place updates)

| Address | What changed |
| --- | --- |
| `module.eks.aws_eks_cluster.this[0]` | `version = "1.32" → "1.33"`. **Cluster ID, role ARN, endpoint, OIDC URL preserved.** |
| `module.eks.module.eks_managed_node_group["ng-0"].aws_eks_node_group.this[0]` | `version = "1.32" → "1.33"`, `release_version` rolls to `1.33.x`-eks-compatible AMI. AWS rolls instances. |
| `module.eks.module.eks_managed_node_group["ng-1"].aws_eks_node_group.this[0]` | Same. |
| `aws_eks_addon.coredns` | Version auto-resolved to 1.33-compatible via the caller's `data "aws_eks_addon_version" "coredns"`. |
| `aws_eks_addon.kube_proxy` | Same. |
| `aws_eks_addon.vpc_cni` | Same (this one's version was already 1.33-compatible from stage 1, but its in-state attributes refreshed). |
| `module.cluster_autoscaler.aws_iam_role.default` | IRSA assume-role policy refresh. |
| `module.cluster_autoscaler.helm_release.cluster-autoscaler` | Helm chart values refresh (image tag rolls forward to a 1.33-compatible build). |
| `module.external_dns.aws_iam_role.default` | IRSA refresh. |
| `module.lb_controller.aws_iam_role.default` | IRSA refresh. |

### Replaced (1, harmless)

| Address | Why |
| --- | --- |
| `module.eks.time_sleep.this[0]` | TF helper. Its `triggers["cluster_version"]` changed `1.32` → `1.33`, which forces replacement on `time_sleep`. Recreated immediately. Zero AWS-side impact. |

### Destroyed

Only the `time_sleep` for replacement, listed above.

### Anomalies / surgical interventions

None.

### Customer-facing impact during stage 2

| Surface | Observed |
| --- | --- |
| `https://j7m4-0430a.wandb.ml/` | continuously responsive, HTTP 200 throughout |
| Cluster API | continuously available (AWS does control-plane upgrades transparently — rolling replacement of control plane nodes, no API downtime) |
| Pod scheduling | One full rolling refresh of both managed node groups as AWS replaces 1.32 AMIs with 1.33 AMIs. Pods drained gracefully and rescheduled onto the new nodes. |
| Add-on pods (CoreDNS, kube-proxy, vpc-cni) | EKS rolls these as part of the add-on version updates. Brief CoreDNS pod restarts could cause sub-second DNS resolution blips — typically masked by client-side DNS caching but worth knowing. |
| Database / cache / S3 / EFS | no changes |
| DNS records / Certificate | no changes |

---

## Stage 3 — EKS 1.33 → 1.34

**Plan headline.** `1 to add, 8 to change, 1 to destroy`, 1 forced
replacement (the same `time_sleep` helper, same reason).

### Added / Changed / Destroyed

Same shape as stage 2, with the version values stepped 1.33 → 1.34. The
plan diff was identical in structure: time_sleep recreate, cluster + node
groups + add-ons + helm-release IRSA all in-place, no other changes.

### Anomalies / surgical interventions

None.

### Customer-facing impact during stage 3

Same shape as stage 2: control plane upgrade transparent, both node
groups rolled their AMIs to `v1.34.7-eks-40737a8`, add-on pods
refreshed. HTTPS endpoint returned 200 throughout.

---

## Stage 4 — retire the `aws-auth` ConfigMap

**Plan headline.** `0 to add, 0 to change, 1 to destroy`. No forced
replacements.

### Added / Changed

None.

### Destroyed (1)

| Address | What it was |
| --- | --- |
| `module.app_eks.kubernetes_config_map.aws_auth_legacy[0]` | The wandb-side adoption of v17's `kube-system/aws-auth` ConfigMap. With `var.preserve_aws_auth_configmap = false`, the resource block's `count` flips to 0, and TF deletes the in-cluster ConfigMap through the kubernetes provider. |

After the destroy, `kubectl -n kube-system get configmap aws-auth`
returns `NotFound`. The cluster authenticates kubelet token refreshes
exclusively through the access-entries table from this point on.

### Anomalies / surgical interventions

None.

### Customer-facing impact during stage 4

| Surface | Observed |
| --- | --- |
| `https://j7m4-0430a.wandb.ml/` | continuously responsive, HTTP 200 |
| Cluster API | continuously available |
| Pod scheduling | none — no node rolling, no new resources, just the configmap delete |
| Auth path | All kubelet, EKS-controller, and SSO admin authentication continued via the AWS-managed access entries. No reschedule, no token refresh failure observed. |
| Add-ons / helm releases / database / cache / DNS / cert | no changes |

This stage was performed ~24 hours after stage 3 — well past one
kubelet credential rotation cycle, which is the soak window in which
any aws-auth-dependent identity would have started failing if access
entries didn't cover it. None did.

---

## Cumulative AWS-side impact across all four stages

What stayed the same end-to-end (verified by direct query of state and
AWS APIs at each stage's verification step):

- EKS cluster ID (`j7m4-0430a`).
- EKS cluster `roleArn`
  (`arn:aws:iam::770934259321:role/j7m4-0430a20260430181736075700000006`,
  the literal v17-era role with random suffix).
- EKS cluster `endpoint`
  (`https://C4E049BEE67C39291B4F454149D9560E.gr7.us-east-2.eks.amazonaws.com`).
- EKS OIDC issuer URL
  (`https://oidc.eks.us-east-2.amazonaws.com/id/C4E049BEE67C39291B4F454149D9560E`).
- The wandb-side
  `aws_iam_openid_connect_provider.eks` ARN, which depends on the OIDC
  URL above.
- All non-EKS infrastructure: VPC, subnets, NAT gateways, route tables,
  RDS Aurora cluster, ElastiCache Redis cluster, S3 file-storage bucket,
  KMS key, EFS filesystem, ALB, target groups, listeners, Route53
  sub-zone, ACM certificate.

What rolled (visible to the data plane):

- Both managed node groups had their EC2 instances replaced once during
  stage 1 (launch-template version update), once during stage 2
  (1.32 → 1.33 AMI roll), and once during stage 3 (1.33 → 1.34 AMI
  roll). Three rolls total per node group, with EKS-managed draining.
  The `aws_eks_node_group` resource itself was preserved in TF state
  across all four stages.

What ended up materially different:

- `terraform-aws-modules/eks/aws` source: vendored v20.37 fork instead of
  registry v17.23.
- AWS Terraform provider: `~> 5.95` instead of `~> 4.0`.
- EKS Kubernetes version: `1.34` instead of `1.32`.
- Cluster auth path: access entries only (with API mode), aws-auth
  ConfigMap retired.
- The 18 v17-only resources from stage 1 (worker IAM role, worker SG,
  v17-only IAM policies, etc.) are gone — all of them either had no v20
  equivalent or were replaced by a v20-named resource the plan created
  in their place.

## Customer-facing impact summary

This deployment is a sandbox with no production traffic. Throughout the
test, every spot-check of `https://j7m4-0430a.wandb.ml/` returned
HTTP 200. No external customer would have noticed the upgrade.

For a *production* deployment running through the same procedure, the
expected user-visible impact would be:

- **HTTPS endpoint**: continuously available. The ALB and certificate
  are unchanged across all four stages; ALB health checks would route
  traffic away from any unhealthy targets during pod reschedules.
- **In-flight HTTP requests during node rolls**: connections to pods
  being drained would be terminated. Clients that retry would land on
  rescheduled pods on healthy nodes; clients that don't would see a
  failure for that one request. Three rolling refreshes total
  (one per stage 1, 2, 3); each refresh drains and replaces both nodes
  in turn over ~12-15 minutes per stage.
- **WebSocket / long-poll connections**: dropped during pod reschedules
  (same window as above). Reconnect logic would be exercised.
- **Database / cache / object store / DNS**: completely untouched. Any
  data persistence relies on these, which is why the upgrade preserves
  cluster identity rather than recreating.
- **Cluster API consumers** (CI/CD that calls `aws eks update-kubeconfig`,
  observability stacks that scrape the metrics-server): continuously
  available. The cluster endpoint and CA cert don't change. SSO admin
  access continues via the access-entry path.

Total expected customer-visible downtime in production:
approximately 30-60 seconds aggregated across the three node-group
roll windows, distributed over the three stages, and only for
connections that happened to hit a draining target without retry
logic. Stage 4 has zero expected impact.
