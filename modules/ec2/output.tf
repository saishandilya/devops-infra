output ansible_instance {
    value = aws_instance.ansible.id
}

output "jenkins_master_instance" {
    value = aws_instance.jenkins_master.id
}

output "jenkins_slave_instance" {
    value = aws_instance.jenkins_slave.id
}