resource "aws_eks_cluster" "instamart" {
  name     = "instamart-prod-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
 # version  = "1.29" # Industry standard: Pin to a specific, stable version

  vpc_config {
    # Dynamically grab the private subnets from our main.tf discovery block
    #subnet_ids              = data.aws_subnets.private.ids
    subnet_ids              = ["subnet-0769daeb35bf414ae", "subnet-0230607fce9ac3b3c"]
    endpoint_private_access = true
    endpoint_public_access  = true 
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}
