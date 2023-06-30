locals {

  context = {
    # Data resources
    aws_region_name = data.aws_region.current.name
    # aws_caller_identity
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_iam_session_context.current.issuer_arn
    # aws_partition
    aws_partition_id         = data.aws_partition.current.id
    aws_partition_dns_suffix = data.aws_partition.current.dns_suffix
  }

  eks_cluster_id     = module.aws_eks.cluster_id
  cluster_ca_base64  = module.aws_eks.cluster_certificate_authority_data
  cluster_endpoint   = module.aws_eks.cluster_endpoint
  vpc_id             = var.vpc_id
  private_subnet_ids = var.private_subnet_ids

  enable_workers            = length(var.self_managed_node_groups) > 0 || length(var.managed_node_groups) > 0 ? true : false
  worker_security_group_ids = local.enable_workers ? compact([module.aws_eks.node_security_group_id]) : []

  node_group_context = {
    # EKS Cluster Config
    eks_cluster_id    = local.eks_cluster_id
    cluster_ca_base64 = local.cluster_ca_base64
    cluster_endpoint  = local.cluster_endpoint
    cluster_version   = var.cluster_version
    # VPC Config
    vpc_id             = local.vpc_id
    private_subnet_ids = local.private_subnet_ids
    public_subnet_ids  = []

    # Worker Security Group
    worker_security_group_ids = local.worker_security_group_ids

    # Data sources
    aws_partition_dns_suffix = local.context.aws_partition_dns_suffix
    aws_partition_id         = local.context.aws_partition_id

    iam_role_path                 = null
    iam_role_permissions_boundary = null

    # Service IPv4/IPv6 CIDR range
    service_ipv6_cidr = null
    service_ipv4_cidr = null

    tags = var.tags
  }

  # Managed node IAM Roles for aws-auth
  managed_node_group_aws_auth_config_map = [
    for key, node in var.managed_node_groups : {
      rolearn : try(node.iam_role_arn, "arn:${local.context.aws_partition_id}:iam::${local.context.aws_caller_identity_account_id}:role/${module.aws_eks.cluster_id}-${node.node_group_name}")
      username : "system:node:{{EC2PrivateDNSName}}"
      groups : [
        "system:bootstrappers",
        "system:nodes"
      ]
    }
  ]

  # Teams
  partition  = local.context.aws_partition_id
  account_id = local.context.aws_caller_identity_account_id

  cluster_iam_role_name        = "${var.cluster_name}-cluster-role"
  cluster_iam_role_pathed_name = local.cluster_iam_role_name
  cluster_iam_role_pathed_arn  = "arn:${local.context.aws_partition_id}:iam::${local.context.aws_caller_identity_account_id}:role/${local.cluster_iam_role_pathed_name}"
}
