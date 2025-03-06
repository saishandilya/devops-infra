# Deploy EC2 Instances (from Local Machine)
module "ec2" {
    source                              = "./modules/ec2"
    ansible_instance_type_value         = var.ansible_instance_type
    jenkins_instance_type_value         = var.jenkins_instance_type
    instance_key_name_value             = var.instance_key_name
    public_subnet_id_value              = var.public_subnet_id_list[0]  # First subnet for EC2
    security_group_id_value             = [var.security_group_id]
}

module "eks" {
    source                              =   "./modules/eks"
    cluster_name_value                  =   var.cluster_name
    cluster_role_value                  =   var.cluster_role_name
    cluster_version_value               =   var.cluster_version
    public_subnet_ids_value_list        =   var.public_subnet_id_list
    worker_node_instance_key_name_value =   var.instance_key_name
    vpc_id_value                        =   var.vpc_id
}