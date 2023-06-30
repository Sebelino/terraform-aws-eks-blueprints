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
