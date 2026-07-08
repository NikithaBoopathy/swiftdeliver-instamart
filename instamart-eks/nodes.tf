resource "aws_eks_node_group" "backend_nodes" {
  cluster_name    = aws_eks_cluster.instamart.name
  node_group_name = "instamart-backend-workers"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  
  # Deploy nodes EXCLUSIVELY into private subnets for maximum security
  #subnet_ids      = data.aws_subnets.private.ids
  subnet_ids = ["subnet-0769daeb35bf414ae", "subnet-0230607fce9ac3b3c"]

  scaling_config {
    desired_size = 2 # The standard running capacity
    min_size     = 2 # Never drop below 2 nodes (High Availability)
    max_size     = 4 # Allow scaling up under heavy traffic
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_read_only
  ]
}
