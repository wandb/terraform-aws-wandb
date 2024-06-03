#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to check if Terraform is installed
check_terraform_installed() {
  if ! command -v terraform &> /dev/null; then
    echo "Terraform could not be found. Please install Terraform."
    exit 1
  fi
}

# Function to check if AWS CLI is installed
check_aws_cli_installed() {
  if ! command -v aws &> /dev/null; then
    echo "AWS CLI could not be found. Please install AWS CLI."
    exit 1
  fi
}

# Function to check if tfstate file exists
check_tfstate_file() {
  if [ ! -f "terraform.tfstate" ]; then
    echo "terraform.tfstate file not found. Please ensure you are in the correct directory."
    exit 1
  fi
}

# Function to update kubeconfig
update_kubeconfig() {
  if [ -z "$1" ]; then
    echo "Cluster name is required to update kubeconfig."
    exit 1
  fi

  CLUSTER_NAME="$1"
  REGION="${2:-$AWS_DEFAULT_REGION}"

  if [ -z "$REGION" ]; then
    echo "Region is required. Please set the AWS_DEFAULT_REGION environment variable or provide it as an argument."
    exit 1
  fi

  echo "Updating kubeconfig for cluster ${CLUSTER_NAME} in region ${REGION}..."
  aws eks update-kubeconfig --name "${CLUSTER_NAME}" --region "${REGION}"
}

# Function to handle pre-Terraform steps
pre_terraform_steps() {
  echo "Running pre-Terraform steps..."

  # Check if Terraform is installed
  check_terraform_installed

  # Check if tfstate file exists
  check_tfstate_file

  # Initialize and upgrade Terraform
  terraform init -upgrade

  # Rename the cluster IAM role TF resource to the new name
  terraform state mv 'module.app_eks.module.eks.aws_iam_role.cluster[0]' 'module.app_eks.module.eks.aws_iam_role.cluster_new[0]'

  # Remove node_groups from TF state
  terraform state rm 'module.app_eks.module.eks.module.node_groups'

  # Remove node groups security group from state
  terraform state rm 'module.app_eks.module.eks.aws_security_group.workers[0]'

  # Remove policy attachment for node groups from TF state
  terraform state rm 'module.app_eks.module.eks.aws_iam_role_policy_attachment.workers_AmazonEKS_CNI_Policy[0]' \
                     'module.app_eks.module.eks.aws_iam_role_policy_attachment.workers_AmazonEKSWorkerNodePolicy[0]' \
                     'module.app_eks.module.eks.aws_iam_role_policy_attachment.workers_AmazonEC2ContainerRegistryReadOnly[0]'

  # Remove node groups AWS security group rule resources from TF state
  for rule in $(terraform state list | grep 'aws_security_group_rule.workers'); do
    terraform state rm "$rule"
  done

  # Remove cluster AWS security group rule resources from TF state
  for rule in $(terraform state list | grep 'aws_security_group_rule.cluster'); do
    terraform state rm "$rule"
  done

  # Remove IAM role for node groups
  terraform state rm 'module.app_eks.module.eks.aws_iam_role.workers[0]'

  # Rename IAM role policy attachments
  terraform state mv 'module.app_eks.module.eks.aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy[0]' 'module.app_eks.module.eks.aws_iam_role_policy_attachment.this["AmazonEKSClusterPolicy"]'
  terraform state mv 'module.app_eks.module.eks.aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceControllerPolicy[0]' 'module.app_eks.module.eks.aws_iam_role_policy_attachment.this["AmazonEKSVPCResourceController"]'

  echo "Pre-Terraform steps completed successfully."
}

# Function to handle post-Terraform steps
post_terraform_steps() {
  echo "Running post-Terraform steps..."

  # Check if AWS CLI is installed
  check_aws_cli_installed

  # Check if the cluster name is provided
  if [ -z "$2" ]; then
    echo "Cluster name is required for post-Terraform steps."
    echo "Usage: $0 --post <cluster-name> [<region>]"
    exit 1
  fi

  CLUSTER_NAME="$2"
  REGION="${3:-$AWS_DEFAULT_REGION}"

  if [ -z "$REGION" ]; then
    echo "Region is required. Please set the AWS_DEFAULT_REGION environment variable or provide it as an argument."
    exit 1
  fi

  # Update kubeconfig
  update_kubeconfig "${CLUSTER_NAME}" "${REGION}"

  # Get the list of node groups with the prefix matching the cluster name
  NODE_GROUPS=$(aws eks list-nodegroups --cluster-name "${CLUSTER_NAME}" --region "${REGION}" --query 'nodegroups[?starts_with(@, `'${CLUSTER_NAME}'`)]' --output text)

  if [ -z "$NODE_GROUPS" ]; then
    echo "No node groups found with the prefix '${CLUSTER_NAME}'."
    exit 1
  fi

  for NODE_GROUP in $NODE_GROUPS; do
    echo "Processing node group: ${NODE_GROUP}"

    # Drain all pods from the node group
    for NODE in $(kubectl get nodes --selector="eks.amazonaws.com/nodegroup=${NODE_GROUP}" -o name); do
      kubectl drain "$NODE" --ignore-daemonsets --delete-local-data --force || true
    done

    # Delete the node group
    aws eks delete-nodegroup --cluster-name "${CLUSTER_NAME}" --nodegroup-name "${NODE_GROUP}" --region "${REGION}"
  done

  echo "Post-Terraform steps completed successfully."
}

# Check the input argument
if [ "$1" == "--pre" ]; then
  pre_terraform_steps
elif [ "$1" == "--post" ]; then
  post_terraform_steps "$@"
else
  echo "Usage: $0 --pre | --post <cluster-name> [<region>]"
  exit 1
fi
