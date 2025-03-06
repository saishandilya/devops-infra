resource "aws_instance" "ansible" {
    ami                     =   data.aws_ami.ubuntu.image_id
    instance_type           =   var.ansible_instance_type_value
    key_name                =   var.instance_key_name_value
    vpc_security_group_ids  =   var.security_group_id_value
    subnet_id               =   var.public_subnet_id_value
    tags                    =   {
        Name        =   "Ansible"
        Project     =   "Devops Practice"
    }

    connection {
        type        = "ssh"
        user        = "ubuntu"
        private_key = file("./modules/ec2/files/${var.instance_key_name_value}.pem")
        host        = self.public_ip
    }

    provisioner "file" {
        source      = "./modules/ec2/files/${var.instance_key_name_value}.pem" # Place your key in this folder which you have created
        destination = "/home/ubuntu/${var.instance_key_name_value}.pem"
    }

    provisioner "file" {
        source = "./modules/ec2/files/jenkins_master_setup.yaml"
        destination = "/home/ubuntu/jenkins_master_setup.yaml"
    }

    provisioner "file" {
        source = "./modules/ec2/files/jenkins_slave_setup.yaml"
        destination = "/home/ubuntu/jenkins_slave_setup.yaml"
    }

    provisioner "file" {
        content     = <<-EOT
            [jenkins_master]
            ${aws_instance.jenkins_master.private_ip}

            [jenkins_master:vars]
            ansible_user=ubuntu
            ansible_ssh_private_key_file=/opt/${var.instance_key_name_value}.pem

            [jenkins_slave]
            ${aws_instance.jenkins_slave.private_ip}

            [jenkins_slave:vars]
            ansible_user=ubuntu
            ansible_ssh_private_key_file=/opt/${var.instance_key_name_value}.pem
        EOT
        destination = "/home/ubuntu/ansible-hosts"
    }

    provisioner "remote-exec" {
        inline = [
            "echo 'Hello!!! Initiating remote exec'",
            "sudo apt update",
            "sudo apt install software-properties-common",
            "sudo add-apt-repository --yes --update ppa:ansible/ansible",
            "sudo apt update",
            "sudo apt install ansible -y",
            "ansible --version",
            "sudo mv /home/ubuntu/${var.instance_key_name_value}.pem /opt/${var.instance_key_name_value}.pem",
            "sudo mv /home/ubuntu/ansible-hosts /opt/ansible-hosts",
            "sudo mv /home/ubuntu/jenkins_master_setup.yaml /opt/jenkins_master_setup.yaml",
            "sudo mv /home/ubuntu/jenkins_slave_setup.yaml /opt/jenkins_slave_setup.yaml",
            "sudo chmod 400 /opt/${var.instance_key_name_value}.pem",
            "export ANSIBLE_HOST_KEY_CHECKING=False",
            "ansible all -i /opt/ansible-hosts -m ping",
            # "ansible-playbook -i /opt/ansible-hosts /opt/jenkins_master_setup.yaml --check",
            "ansible-playbook -i /opt/ansible-hosts /opt/jenkins_master_setup.yaml",
            # "ansible-playbook -i /opt/ansible-hosts /opt/jenkins_slave_setup.yaml --check",
            "ansible-playbook -i /opt/ansible-hosts /opt/jenkins_slave_setup.yaml",
            "echo 'Fetching installed version from Jenkins Master: '",
            "ansible jenkins_master -i /opt/ansible-hosts -m shell -a 'java -version && jenkins --version'",
            "echo 'Fetching installed version from Jenkins Slave: '",
            "ansible jenkins_slave -i /opt/ansible-hosts -m shell -a 'java -version && /opt/apache-maven-3.9.6/bin/mvn -version && docker --version'",
            # "echo 'Fetching installed version from Jenkins Master: '", 
            # "ansible jenkins_master -i /opt/ansible-hosts -m shell -a \"echo 'Jenkins: $(jenkins --version)' && echo 'Java: $(java -version 2>&1 | head -n 1)'\"",
            # "echo 'Fetching installed version from Jenkins Slave: '",
            # "ansible jenkins_slave -i /opt/ansible-hosts -m shell -a \"echo 'Java: $(java -version 2>&1 | head -n 1)' && echo 'Maven: $(/opt/apache-maven-3.9.6/bin/mvn -version | head -n 1)' && echo 'Docker: $(docker --version | head -n 1)'\"",
            "echo 'Fetching Jenkins Admin Password from Jenkins Master...'",
            "ssh -o StrictHostKeyChecking=no -i /opt/${var.instance_key_name_value}.pem ubuntu@${aws_instance.jenkins_master.public_ip} 'sudo cat /var/lib/jenkins/secrets/initialAdminPassword'"
        ]
    }
}

resource "aws_instance" "jenkins_master" {
    ami                     =   data.aws_ami.ubuntu.image_id
    instance_type           =   var.jenkins_instance_type_value
    key_name                =   var.instance_key_name_value
    vpc_security_group_ids  =   var.security_group_id_value
    subnet_id               =   var.public_subnet_id_value
    tags                    =   {
        Name        =   "Jenkins Master"
        Project     =   "Devops Practice"
    }
}

resource "aws_instance" "jenkins_slave" {
    ami                     =   data.aws_ami.ubuntu.image_id
    instance_type           =   var.jenkins_instance_type_value
    key_name                =   var.instance_key_name_value
    vpc_security_group_ids  =   var.security_group_id_value
    subnet_id               =   var.public_subnet_id_value
    tags                    =   {
        Name        =   "Jenkins Slave"
        Project     =   "Devops Practice"
    }
}