output "cluster_endpoint" {
  value = aws_eks_cluster.eks.endpoint
}

output "cluster_arn_value" {
  value = aws_eks_cluster.eks.arn
}