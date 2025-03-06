# EKS Cluster
resource "aws_eks_cluster" "eks" {
    name = var.cluster_name_value
    role_arn = aws_iam_role.eks_cluster_role.arn
    version  = var.cluster_version_value

    vpc_config {
        subnet_ids = var.public_subnet_ids_value_list
    }
    depends_on = [
        aws_iam_role_policy_attachment.AmazonEKSClusterPolicy,
    ]
}

# EKS Cluster Role
resource "aws_iam_role" "eks_cluster_role" {
    name = var.cluster_role_value
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
        Action = [
            "sts:AssumeRole"
            #,
            # "sts:TagSession"
            ]
        Effect = "Allow"
        Principal = {
            Service = "eks.amazonaws.com"
            }
        },
    ]
    })
}

# EKS Cluster Policy
resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
    role       = aws_iam_role.eks_cluster_role.name
}

# EKS Worker Node Security Group
resource "aws_security_group" "eks_worker_node_sg" {
    name        = var.worker_node_sg_name
    description = "Allow SSH and HTTPS inbound traffic"
    vpc_id      =  var.vpc_id_value

    ingress {
        description      = "ssh access to public"
        from_port        = 22
        to_port          = 22
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }
    ingress {
        description      = "https public access"
        from_port        = 443
        to_port          = 443
        protocol         = "tcp"
        cidr_blocks      = ["0.0.0.0/0"]
    }

    egress {
        from_port        = 0
        to_port          = 0
        protocol         = "-1"
        cidr_blocks      = ["0.0.0.0/0"]
    }

}

# EKS WorkerNode Role
resource "aws_iam_role" "eks_worker_node_role" {
    name = var.worker_node_role_value
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
        {
        Action = ["sts:AssumeRole"]
        Effect = "Allow"
        Principal = {
            Service = "ec2.amazonaws.com"
            }
        },
    ]
    })
}


# EKS Worker Node Policy
resource "aws_iam_role_policy_attachment" "AmazonEKSWorkerNodePolicy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
    role       = aws_iam_role.eks_worker_node_role.name
}

# EKS Worker EKS CNI Policy
resource "aws_iam_role_policy_attachment" "AmazonEKS_CNI_Policy" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
    role       = aws_iam_role.eks_worker_node_role.name
}

# EKS SSM Managed Instance Core Policy
resource "aws_iam_role_policy_attachment" "AmazonSSMManagedInstanceCore" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    role       = aws_iam_role.eks_worker_node_role.name
}

# EKS EC2 Container Registry Read Only Policy
resource "aws_iam_role_policy_attachment" "AmazonEC2ContainerRegistryReadOnly" {
    policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
    role       = aws_iam_role.eks_worker_node_role.name
}

# EKS Worker Node Instance Profile
resource "aws_iam_instance_profile" "eks_worker_node_instance_profile" {
    name       = var.worker_node_instance_profile_name
    role       = aws_iam_role.eks_worker_node_role.name
    depends_on = [
        aws_iam_role.eks_worker_node_role,
        # aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
        # aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
        # aws_iam_role_policy_attachment.AmazonSSMManagedInstanceCore,
        # aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly
    ]
}

# EKS Worker Node Group
resource "aws_eks_node_group" "eks_worker_node" {
    cluster_name    = aws_eks_cluster.eks.name
    node_group_name = var.worker_node_group_name
    node_role_arn   = aws_iam_role.eks_worker_node_role.arn
    subnet_ids      = var.public_subnet_ids_value_list

    # capacity_type = "ON_DEMAND"
    # disk_size = "20"
    instance_types = [var.worker_node_group_instance_type]

    remote_access {
        ec2_ssh_key = var.worker_node_instance_key_name_value
        source_security_group_ids = [aws_security_group.eks_worker_node_sg.id]
    }

    scaling_config {
        desired_size = 2
        max_size     = 2
        min_size     = 1
    }

    update_config {
        max_unavailable = 1
    }

    depends_on = [
        aws_iam_role_policy_attachment.AmazonEKSWorkerNodePolicy,
        aws_iam_role_policy_attachment.AmazonEKS_CNI_Policy,
        aws_iam_role_policy_attachment.AmazonEC2ContainerRegistryReadOnly,
        aws_iam_role_policy_attachment.AmazonSSMManagedInstanceCore
    ]
}