resource "aws_kms_key" "this" {
  description             = "${var.cluster_name} EKS cluster secret encryption key"
  policy                  = data.aws_iam_policy_document.eks_key.json
  enable_key_rotation     = true
  deletion_window_in_days = 30
  tags                    = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.cluster_name}"
  target_key_id = aws_kms_key.this.key_id
}

module "aws_eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "v18.29.1"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  iam_role_use_name_prefix = false
  iam_role_name            = local.cluster_iam_role_name

  subnet_ids                           = var.private_subnet_ids
  cluster_endpoint_private_access      = false
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]

  vpc_id = var.vpc_id

  create_cloudwatch_log_group = false
  cluster_enabled_log_types   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  attach_cluster_encryption_policy = false
  cluster_encryption_config = [
    {
      provider_key_arn = aws_kms_key.this.arn
      resources        = ["secrets"]
    }
  ]
  tags = var.tags
}

module "aws_eks_managed_node_groups" {
  source = "./modules/aws-eks-managed-node-groups"

  for_each = var.managed_node_groups

  managed_ng = each.value
  context    = local.node_group_context

  depends_on = [kubernetes_config_map.aws_auth]
}

resource "kubernetes_config_map" "aws_auth" {
  count = 1

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
    labels = {
      "app.kubernetes.io/managed-by" = "terraform-aws-eks-blueprints"
      "app.kubernetes.io/created-by" = "terraform-aws-eks-blueprints"
    }
  }

  data = {
    mapRoles = yamlencode(
      distinct(concat(
        local.managed_node_group_aws_auth_config_map,
        var.map_roles,
      ))
    )
    mapUsers    = yamlencode([])
    mapAccounts = yamlencode([])
  }

  depends_on = [module.aws_eks.cluster_id, data.http.eks_cluster_readiness[0]]
}
