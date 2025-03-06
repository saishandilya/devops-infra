output ansible_instance_id {
    value = try(module.ec2.ansible_instance, null)
}

output "jenkins_master_instance_id" {
    value = try(module.ec2.jenkins_master_instance, null)
}

output "jenkins_slave_instance_id" {
    value = try(module.ec2.jenkins_slave_instance, null)
}

output "eks_cluster_endpoint" {
  value = try(module.eks.cluster_endpoint, null)
}

output "eks_cluster_arn_value" {
  value = try(module.eks.cluster_arn_value, null)
}