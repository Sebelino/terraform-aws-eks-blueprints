module "kms" {
  count  = 1
  source = "./modules/aws-kms"

  alias                   = "alias/${var.cluster_name}"
  description             = "${var.cluster_name} EKS cluster secret encryption key"
  policy                  = data.aws_iam_policy_document.eks_key.json
  deletion_window_in_days = 30
  tags                    = var.tags
}

module "aws_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v18.29.1"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  iam_role_use_name_prefix = false
  iam_role_name            = local.cluster_iam_role_name

  subnet_ids                           = var.private_subnet_ids
  cluster_endpoint_private_access      = var.cluster_endpoint_private_access
  cluster_endpoint_public_access       = var.cluster_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.cluster_endpoint_public_access_cidrs
  cluster_ip_family                    = var.cluster_ip_family
  cluster_service_ipv4_cidr            = var.cluster_service_ipv4_cidr

  vpc_id = var.vpc_id

  create_cloudwatch_log_group            = false
  cluster_enabled_log_types              = var.cluster_enabled_log_types
  cloudwatch_log_group_retention_in_days = var.cloudwatch_log_group_retention_in_days
  cloudwatch_log_group_kms_key_id        = var.cloudwatch_log_group_kms_key_id

  attach_cluster_encryption_policy = false
  cluster_encryption_config = [
    {
      provider_key_arn = try(module.kms[0].key_arn, var.cluster_kms_key_arn)
      resources        = ["secrets"]
    }
  ]
  cluster_identity_providers = var.cluster_identity_providers

  tags = var.tags
}
