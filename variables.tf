variable "ansible_instance_type" {
    default     = "" #e.g "t2.micro"
    description = "Instance type for Ansible Instance"
}

variable "jenkins_instance_type" {
    default     = "" #e.g "t2.medium"
    description = "Instance type for Jenkins Instance"
}

variable "instance_key_name" {
    default     = "" # e.g "devops-training"
    description = "EC2 instance key name"
}

variable "security_group_id"{
    description = "Security Group ID for EC2 Instance"
    default     = "" # e.g "sg-xxxxxxxxxxxxxxxxx"
}

variable "public_subnet_id_list" {
    description = "Default VPC public subnet id list"
    type        = list(string)
    default     = [] # e.g ["subnet-xxxxxxxxxx", "subnet-xxxxxxxxxxxx", "subnet-xxxxxxxxxxxxxx"]
}


variable "cluster_name" {
    description = "EKS Cluster name"
    default     = "" # e.g "devops-cluster"
}

variable "cluster_role_name" {
    description = "EKS Cluster role name"
    default     = "" # e.g "eksClusterRole"
}

variable "cluster_version" {
    description = "EKS Cluster Version"
    default     = "" # e.g "1.31"
}

variable "vpc_id" {
    description = "VPC ID"
    default     = "" # e.g "vpc-xxxxxxxxxxxxx"
}