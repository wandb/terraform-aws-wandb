# EKS Addon Compatibility Matrix

Versions shown are upstream component versions (`-eksbuild.N` suffix omitted). **min** \= oldest supported eksbuild for that K8s minor version **def** \= AWS-installed default on a new cluster **max** \= latest available eksbuild (May 2026\)

The `local.eks_addon_default_versions` map in `add-ons.tf` is sourced from the **def** row of this matrix and appends `-eksbuild.1` to each value. To pin a specific eksbuild suffix, set the corresponding `eks_addon_*_version` variable.

Confirm live:

```shell
aws eks describe-addon-versions --addon-name <name> --kubernetes-version <ver>
```

---

## Support status

| Version | Status |
| :---- | :---- |
| 1.29 | Extended support |
| 1.30 | Extended support |
| 1.31 | Extended support |
| 1.32 | Standard support |
| 1.33 | Standard support |
| 1.34 | Standard support |
| 1.35 | Standard support |

---

## Amazon VPC CNI (`vpc-cni`)

Auto-installed addon — not automatically upgraded when you upgrade the control plane. You must update it manually.

|  | 1.29 | 1.30 | 1.31 | 1.32 | 1.33 | 1.34 | 1.35 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **min** | v1.11.4 | v1.12.6 | v1.14.1 | v1.16.0 | v1.18.0 | v1.19.0 | v1.19.0 |
| **def** | v1.18.5 | v1.18.5 | v1.19.5 | v1.19.5 | v1.20.4 | v1.21.1 | v1.21.1 |
| **max** | v1.21.1 | v1.21.1 | v1.21.1 | v1.21.1 | v1.21.1 | v1.21.1 | v1.21.1 |

---

## CoreDNS (`coredns`)

Auto-installed addon — not automatically upgraded when you upgrade the control plane. You must update it manually.

|  | 1.29 | 1.30 | 1.31 | 1.32 | 1.33 | 1.34 | 1.35 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **min** | v1.8.7 | v1.9.3 | v1.10.1 | v1.11.1 | v1.11.1 | v1.11.3 | v1.11.3 |
| **def** | v1.11.1 | v1.11.1 | v1.11.3 | v1.11.3 | v1.12.1 | v1.12.4 | v1.13.2 |
| **max** | v1.11.4 | v1.11.4 | v1.11.4 | v1.11.4 | v1.13.2 | v1.13.2 | v1.13.2 |

---

## kube-proxy (`kube-proxy`)

Auto-installed addon — not automatically upgraded when you upgrade the control plane. You must update it manually.

|  | 1.29 | 1.30 | 1.31 | 1.32 | 1.33 | 1.34 | 1.35 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **min** | v1.28.1 | v1.29.0 | v1.30.0 | v1.31.0 | v1.32.0 | v1.33.0 | v1.34.0 |
| **def** | v1.29.0 | v1.30.0 | v1.31.2 | v1.32.3 | v1.33.0 | v1.34.0 | v1.35.0 |
| **max** | v1.29.15 | v1.30.14 | v1.31.14 | v1.32.11 | v1.33.7 | v1.34.3 | v1.35.0 |

---

## Amazon EBS CSI Driver (`aws-ebs-csi-driver`)

Ships on its own release cadence independent of Kubernetes versions. The `max` values below reflect the latest available as of May 2026 — verify with the CLI as this changes frequently.

|  | 1.29 | 1.30 | 1.31 | 1.32 | 1.33 | 1.34 | 1.35 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **min** | v1.20.0 | v1.20.0 | v1.26.0 | v1.26.0 | v1.31.0 | v1.50.0 | v1.50.0 |
| **def** | v1.28.0 | v1.31.0 | v1.35.0 | v1.42.0 | v1.51.0 | v1.55.0 | v1.57.0 |
| **max** | v1.44.0 | v1.44.0 | v1.44.0 | v1.44.0 | v1.57.0 | v1.57.0 | v1.57.0 |

---

## Amazon EFS CSI Driver (`aws-efs-csi-driver`)

Ships on its own release cadence independent of Kubernetes versions. The `max` values below reflect the latest available as of May 2026 — verify with the CLI as this changes frequently.

|  | 1.29 | 1.30 | 1.31 | 1.32 | 1.33 | 1.34 | 1.35 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **min** | v1.5.8 | v1.7.0 | v2.0.0 | v2.0.0 | v2.0.0 | v2.0.0 | v2.0.0 |
| **def** | v2.0.3 | v2.0.3 | v2.0.7 | v2.0.7 | v2.1.4 | v2.1.6 | v2.1.6 |
| **max** | v2.1.6 | v2.1.6 | v2.1.6 | v2.1.6 | v2.1.6 | v2.1.6 | v2.1.6 |

---

## Metrics Server (`metrics-server`)

Community addon — AWS validates Kubernetes version compatibility only. Version is effectively K8s-agnostic across all supported EKS versions.

|  | 1.29 | 1.30 | 1.31 | 1.32 | 1.33 | 1.34 | 1.35 |
| :---- | :---- | :---- | :---- | :---- | :---- | :---- | :---- |
| **min** | v0.6.3 | v0.6.3 | v0.6.3 | v0.6.3 | v0.6.3 | v0.6.3 | v0.6.3 |
| **def** | v0.7.2 | v0.7.2 | v0.7.2 | v0.7.2 | v0.7.2 | v0.7.2 | v0.7.2 |
| **max** | v0.7.2 | v0.7.2 | v0.7.2 | v0.7.2 | v0.7.2 | v0.7.2 | v0.7.2 |

---

## Useful CLI commands

```shell
# List all versions available for each addon on a given K8s version
for addon in vpc-cni coredns kube-proxy aws-ebs-csi-driver aws-efs-csi-driver metrics-server; do
  echo "=== $addon ==="
  aws eks describe-addon-versions \
    --addon-name $addon \
    --kubernetes-version <k8s-version> \
    --query 'addons[0].addonVersions[].{version:addonVersion,default:compatibilities[0].defaultVersion}' \
    --output table
done

# Check the currently installed version on a cluster for each addon
for addon in vpc-cni coredns kube-proxy aws-ebs-csi-driver aws-efs-csi-driver metrics-server; do
  version=$(aws eks describe-addon \
    --cluster-name <cluster-name> \
    --addon-name $addon \
    --query 'addon.addonVersion' \
    --output text 2>/dev/null || echo "not installed")
  printf '%-25s %s\n' "$addon" "$version"
done

```

