# ClickHouse for Weave Self-Managed

This Terraform module deploys ClickHouse on AWS EKS for use with Weave self-managed deployments. It creates a highly available ClickHouse cluster using the Altinity Kubernetes Operator with S3 storage integration.

## Architecture

The deployment includes:
- **ClickHouse Cluster**: Configurable shards and replicas for high availability
- **ClickHouse Keeper**: Distributed coordination service (ZooKeeper replacement)
- **S3 Storage**: Primary storage with local caching for performance
- **IAM Integration**: Service accounts with IRSA for secure S3 access
- **Altinity Operator**: Kubernetes operator for ClickHouse lifecycle management

## Prerequisites

1. **EKS Cluster**: Existing EKS cluster with:
   - Node specifications: 8+ cores, 64+ GB RAM, 200+ GB disk per node
   - OIDC provider enabled for IRSA
   - Storage class configured (e.g., `gp3`)

2. **Weave License**: Valid Weave self-managed license from W&B

3. **AWS Permissions**: Terraform execution role needs permissions for:
   - S3 bucket creation and management
   - IAM role and policy creation
   - EKS cluster access

## Quick Start

1. **Configure Variables**: Create a `terraform.tfvars` file:

```hcl
# Required variables
region              = "us-west-2"
namespace           = "my-org"
eks_cluster_name    = "my-eks-cluster"
oidc_provider_arn   = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/ABCDEF1234567890"
s3_kms_key_arn      = "arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012"

# Optional: Customize cluster configuration
clickhouse_replicas = 3
clickhouse_shards   = 1
keeper_replicas     = 3

# Optional: Enable external access
create_external_service = true
external_service_type   = "LoadBalancer"
allowed_cidr_blocks     = ["10.0.0.0/8"]
```

2. **Deploy Infrastructure**:

```bash
terraform init
terraform plan
terraform apply
```

3. **Verify Deployment**:

```bash
# Check ClickHouse pods
kubectl get pods -n clickhouse

# Test connection
kubectl exec -n clickhouse -it clickhouse-cluster-0-0-0 -- clickhouse-client
```

## Configuration Options

### Cluster Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `clickhouse_replicas` | Number of replicas per shard | 3 |
| `clickhouse_shards` | Number of shards | 1 |
| `keeper_replicas` | Number of Keeper instances | 3 |

### Resource Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `clickhouse_cpu_request` | CPU request per pod | 4 |
| `clickhouse_memory_request` | Memory request per pod | 32Gi |
| `clickhouse_storage_size` | Persistent storage per pod | 200Gi |

### Storage Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `enable_s3_storage` | Use S3 as primary storage | true |
| `s3_cache_size` | Local S3 cache size | 10Gi |
| `storage_class_name` | Kubernetes storage class | gp3 |

## Weave Integration

After deployment, configure Weave to use ClickHouse:

### Environment Variables

Set these in your Weave deployment:

```yaml
env:
  - name: WF_CLICKHOUSE_HOST
    value: "clickhouse-weave-clickhouse.clickhouse.svc.cluster.local"
  - name: WF_CLICKHOUSE_PORT
    value: "9000"
  - name: WF_CLICKHOUSE_USER
    value: "clickhouse"
  - name: WF_CLICKHOUSE_PASSWORD
    valueFrom:
      secretKeyRef:
        name: clickhouse-credentials
        key: password
  - name: WF_CLICKHOUSE_DATABASE
    value: "default"
  - name: WF_CLICKHOUSE_REPLICATED
    value: "true"  # Set to "false" for single-replica setups
  - name: WF_CLICKHOUSE_CLUSTER
    value: "weave-clickhouse"
```

### Connection Details

Use the Terraform outputs to get connection information:

```bash
terraform output connection_info
terraform output weave_integration_config
```

## Monitoring and Maintenance

### Health Checks

```bash
# Check cluster status
kubectl exec -n clickhouse -it clickhouse-cluster-0-0-0 -- clickhouse-client --query "SELECT * FROM system.clusters"

# Check replication status
kubectl exec -n clickhouse -it clickhouse-cluster-0-0-0 -- clickhouse-client --query "SELECT * FROM system.replicas"

# Check S3 disk usage
kubectl exec -n clickhouse -it clickhouse-cluster-0-0-0 -- clickhouse-client --query "SELECT * FROM system.disks"
```

### Backup and Recovery

The module supports automated S3 backups:

```hcl
enable_backups = true
backup_schedule = "0 2 * * *"  # Daily at 2 AM
backup_retention_days = 30
```

### Scaling

To scale the cluster:

1. Update `clickhouse_replicas` or `clickhouse_shards`
2. Run `terraform apply`
3. Wait for new pods to join the cluster

## Security

### Network Security

- Network policies restrict inter-pod communication
- Service accounts use IRSA for AWS access
- S3 buckets are encrypted with KMS
- TLS can be enabled for client connections

### Access Control

```hcl
# Restrict access to specific namespaces
allowed_namespaces = ["weave", "wandb", "monitoring"]

# Configure allowed CIDR blocks for external access
allowed_cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12"]
```

## Troubleshooting

### Common Issues

1. **Pods Stuck in Pending**: Check node resources and storage class availability
2. **S3 Access Denied**: Verify OIDC provider ARN and IAM permissions
3. **Keeper Connection Issues**: Ensure keeper pods are running and accessible

### Debugging Commands

```bash
# Check operator logs
kubectl logs -n clickhouse -l app=clickhouse-operator

# Check pod events
kubectl describe pod -n clickhouse clickhouse-cluster-0-0-0

# Check service connectivity
kubectl exec -n clickhouse -it clickhouse-cluster-0-0-0 -- nslookup clickhouse-keeper
```

### Performance Tuning

For high-performance workloads:

```hcl
# Increase resources
clickhouse_cpu_limit = "16"
clickhouse_memory_limit = "128Gi"

# Tune cache sizes
uncompressed_cache_size = "17179869184"  # 16GB
mark_cache_size = "10737418240"          # 10GB
s3_cache_size = "50Gi"

# Configure node affinity
node_selector = {
  "node.kubernetes.io/instance-type" = "r6i.4xlarge"
}
```

## Cleanup

To remove all resources:

```bash
terraform destroy
```

This will delete the ClickHouse cluster, S3 bucket, IAM roles, and all associated resources.

## Support

For issues with:
- **ClickHouse configuration**: Check [ClickHouse documentation](https://clickhouse.com/docs)
- **Altinity Operator**: Check [Altinity documentation](https://docs.altinity.com/altinitykubernetesoperator/)
- **Weave integration**: Contact W&B support with your deployment details

## Advanced Configuration

### Custom ClickHouse Settings

You can customize ClickHouse settings by modifying the `kubernetes_manifest` resources in `main.tf`. Key settings include:

```yaml
settings:
  max_connections: 4096
  max_concurrent_queries: 100
  max_memory_usage: 10000000000
  storage_configuration:
    policies:
      s3_main:
        volumes:
          main:
            disk: s3
```

### Multi-Region Setup

For multi-region deployments, deploy this module in each region and configure cross-region replication as needed.

### Integration with Existing Monitoring

The module exposes metrics endpoints that can be scraped by Prometheus:
- ClickHouse metrics: `:8123/metrics`
- System metrics: `:8123/?query=SELECT * FROM system.metrics`

Configure your monitoring stack to scrape these endpoints for comprehensive observability.