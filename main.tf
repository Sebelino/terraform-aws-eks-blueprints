locals {
  cluster_encryption_config = length(var.cluster_encryption_config) > 0 ? var.cluster_encryption_config : [
    {
      provider_key_arn = try(module.kms[0].key_arn, var.cluster_kms_key_arn)
      resources        = ["secrets"]
    }
  ]
}

module "kms" {
  count  = var.create_eks && var.cluster_kms_key_arn == null && var.enable_cluster_encryption ? 1 : 0
  source = "./modules/aws-kms"

  alias                   = "alias/${var.cluster_name}"
  description             = "${var.cluster_name} EKS cluster secret encryption key"
  policy                  = data.aws_iam_policy_document.eks_key.json
  deletion_window_in_days = var.cluster_kms_key_deletion_window_in_days
  tags                    = var.tags
}

module "aws_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v18.29.1"

  create = var.create_eks

  cluster_name     = var.cluster_name
  cluster_version  = var.cluster_version
  cluster_timeouts = var.cluster_timeouts

  create_iam_role               = var.create_iam_role
  iam_role_arn                  = var.iam_role_arn
  iam_role_use_name_prefix      = false
  iam_role_name                 = local.cluster_iam_role_name
  iam_role_path                 = var.iam_role_path
  iam_role_description          = var.iam_role_description
  iam_role_permissions_boundary = var.iam_role_permissions_boundary
  iam_role_additional_policies  = var.iam_role_additional_policies

  subnet_ids                           = var.private_subnet_ids
  control_plane_subnet_ids             = var.control_plane_subnet_ids
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_ip_family                    = var.cluster_ip_family
  cluster_service_ipv4_cidr            = var.cluster_service_ipv4_cidr

  vpc_id                                     = var.vpc_id
  create_cluster_security_group              = var.create_cluster_security_group
  cluster_security_group_id                  = var.cluster_security_group_id
  cluster_security_group_name                = var.cluster_security_group_name
  cluster_security_group_use_name_prefix     = var.cluster_security_group_use_name_prefix
  cluster_security_group_description         = var.cluster_security_group_description
  cluster_additional_security_group_ids      = var.cluster_additional_security_group_ids
  cluster_security_group_additional_rules    = var.cluster_security_group_additional_rules
  cluster_security_group_tags                = var.cluster_security_group_tags
  create_cluster_primary_security_group_tags = var.create_cluster_primary_security_group_tags

  create_node_security_group           = var.create_node_security_group
  node_security_group_name             = var.node_security_group_name
  node_security_group_use_name_prefix  = var.node_security_group_use_name_prefix
  node_security_group_description      = var.node_security_group_description
  node_security_group_additional_rules = var.node_security_group_additional_rules
  node_security_group_tags             = var.node_security_group_tags

  enable_irsa              = var.enable_irsa
  openid_connect_audiences = var.openid_connect_audiences
  custom_oidc_thumbprints  = var.custom_oidc_thumbprints

  create_cloudwatch_log_group            = var.create_cloudwatch_log_group
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.cloudwatch_log_group_kms_key_id

  attach_cluster_encryption_policy = false
  cluster_encryption_config        = var.enable_cluster_encryption ? local.cluster_encryption_config : []
  cluster_identity_providers       = var.cluster_identity_providers

  tags = var.tags
}
