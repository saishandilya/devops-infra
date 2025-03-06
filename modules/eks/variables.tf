variable "cluster_name_value" {
    description = "EKS Cluster Name"
}

variable "cluster_role_value" {
    default = "eks_cluster_role"
    description = "EKS Cluster Role"
}

variable "cluster_version_value" {
    description = "EKS Cluster Version"
}

variable "public_subnet_ids_value_list" {
    description = "EKS Cluster Subnet ID's"
}

variable "worker_node_role_value" {
    default = "eks_worker_node_role"
    description = "EKS Worker Node Role"
}

variable "worker_node_instance_profile_name" {
    default = "eks_worker_node_profile"
    description = "EKS Worker Node Instance Profile"
}

variable "worker_node_group_name" {
    default = "eks_devops_node_group"
    description = "EKS Worker Node Group"
}

variable "worker_node_group_instance_type" {
    default = "t2.small"
    description = "EKS Worker Node Group Instance Type"
}

variable "worker_node_instance_key_name_value" {
    description = "EKS Worker Node Group Key Pair"
}

variable "worker_node_sg_name" {
    description = "EKS Worker Node Security Group Name"
    default = "eks_worker_node_sg"
}

variable "vpc_id_value" {
    description = "VPC ID"
}