# Infrastructure Terraform

## 1. Introduction
This repository contains Terraform code with two modules:
1. **EC2** - This module provisions *three* EC2 instances for the **Ansible control node, Jenkins master,** and **Jenkins slave**. It also **ensures connectivity** between Ansible and the Jenkins nodes for seamless software installation.
2. **EKS** - This module sets up an **EKS cluster** along with essential components, including the **Cluster Role, Worker Node Group, Worker Node Security Group,** and **Worker Node Role**.

## 2. Project Structure
This section explains the structure of the repository and the purpose of each file and folder.
```sh
/devops-infra  
│── /modules  
│   ├── /ec2                                # EC2 module for provisioning instances                     
│   │   ├── /files                          # Stores essential configuration and scripts for setup          
│   │   │   ├── ansible-hosts               # Inventory file for Ansible to manage Jenkins nodes
│   │   │   ├── devops-master-key.pem       # Private key for SSH connectivity
│   │   │   ├── jenkins_master_setup.yaml   # Ansible playbook for Jenkins Master setup
│   │   │   ├── jenkins_slave_setup.yaml    # Ansible playbook for Jenkins Slave setup
│   │   ├── main.tf                         # Defines EC2 instance creation and provisioning
│   │   ├── variables.tf                    # Input variables for EC2 module  
│   │   ├── outputs.tf                      # Output values for EC2 module  
│   │   ├── data.tf                         # Retrieves the latest Ubuntu AMI dynamically 
│   ├── /eks                                # EKS module for cluster setup  
│   │   ├── main.tf                         # Defines EKS cluster, worker nodes, and roles  
│   │   ├── variables.tf                    # Input variables for EKS module  
│   │   ├── outputs.tf                      # Output values for EKS module  
│
│── /readmes                                # Folder containing detailed documentation files
│   ├── infrastructure-terraform.md         # Detailed guide on EC2 & EKS provisioning
│   ├── eks-cluster-setup.md                # Detailed guide on EKS Cluster setup using Terraform
│   ├── helm-charts.md                      # Detailed guide on custom helm chart creation and implementation
│
├── backend.tf                              # Configures remote Terraform backend (S3)  
├── main.tf                                 # Calls EC2 and EKS modules  
├── provider.tf                             # Defines AWS provider configuration  
├── variables.tf                            # Global input variables
├── output.tf                               # Outputs values of Terraform-created resources  
├── ec2.tfvars                              # Variable values for EC2 module  
├── eks.tfvars                              # Variable values for EKS module  
├── .gitignore                              # Excludes sensitive files like tfvars, tfstate and key pairs  
└── README.md                               # Documentation for project setup  
```

#### Explanation of Key Components
- `/modules/ec2` – Manages the provisioning of 3 EC2 instances, including remote SSH connectivity and user data for software installation.
- `/modules/ec2/files` – Contains essential configuration files and scripts required for provisioning and setup, including the Ansible inventory file, private SSH key, and playbooks for the Jenkins master and slave nodes.
- `/modules/eks` – Deploys an EKS cluster with worker nodes, worker node security group and required IAM roles.
- `/readmes` – Folder contains detailed documentation files, each explaining different components of the project.
- `backend.tf` – Stores the Terraform state file configuration remotely in an S3 bucket to enable team collaboration.
- `main.tf` – Calls the EC2 and EKS modules to deploy resources.
- `provider.tf` – Defines AWS as the cloud provider and sets up authentication.
- `variables.tf` – Stores input variables used across Terraform configurations.
- `output.tf` – Displays important resource details after deployment (e.g., EC2 Instance ID's, EKS cluster Arn and cluster end point).
- `ec2.tfvars` & `eks.tfvars` – Holds variable values specific to EC2 and EKS deployments.
- `.gitignore` – Ensures sensitive files like .tfvars, .tfstate and SSH keys are not pushed to GitHub.
- `README.md` – Provides documentation for entire project setup and deployment.

## 3. Terraform Configuration
1. **Provider Configuration**
    -   The `provider.tf` file defines the **AWS provider**, which allows Terraform to interact with AWS resources.

        - It specifies the AWS provider from HashiCorp with version `~> 5.0` (i.e., any version of the AWS provider within **5.x**).
        - The `provider "aws"` block sets the AWS region where resources will be created (`us-east-1` in this case).
    - This configuration ensures Terraform can authenticate and deploy resources in the specified AWS region.
2. **Backend Configuration**
    - The `backend.tf` file defines the **S3 backend** configuration for storing the **Terraform state file**, ensuring persistence and team collaboration.

        - `bucket` → Name of the existing S3 bucket that stores the Terraform state file.
        - `key` → Defines the path where the state file will be stored. This is left empty here and will be specified during execution `(e.g., ec2/terraform.tfstate)`.
        - `region` → Specifies the AWS region where the S3 bucket is located.
    - This setup enables **remote state management**, allowing Terraform to track infrastructure changes efficiently while ensuring state **consistency across multiple users**.
3. **Defining Variables**
    - The `variables.tf` file defines **input variables** that pass values to the `main.tf` file, making the Terraform configuration dynamic and reusable.
        - `ansible_instance_type` → Specifies the **instance type** for the **Ansible control node**.
        - `jenkins_instance_type` → Specifies the **instance type** for the **Jenkins master and slave nodes**.
        - `instance_key_name` → Name of the **SSH key pair** for EC2 access.
        - `security_group_id` → **Security group ID** assigned to EC2 instances.
        - `public_subnet_id_list` → **List** of **public subnet IDs** in the default VPC.
        - `cluster_name` → Name of the **EKS cluster**.
        - `cluster_role_name` → **IAM role name** for the EKS cluster.
        - `cluster_version` → **Kubernetes version** for the EKS cluster.
        - `vpc_id` → **VPC ID** where the EKS cluster will be deployed.
    - Each variable is left empty by default and can be defined in a **.tfvars file** `(e.g., ec2.tfvars or eks.tfvars)` before running Terraform.
4. **Terraform Variable Files**
    - The **Terraform Variable Files** `(ec2.tfvars and eks.tfvars)` store specific values for **EC2** and **EKS** resources, allowing for easy customization and separation of concerns.
        - `ec2.tfvars`: Defines values related to EC2 instances, including instance types, security groups, SSH key name, and subnet IDs.
        - `eks.tfvars`: Specifies values for the EKS cluster, such as cluster name, role, version, VPC, SSH key name, and subnet IDs.
    - These files ensure that Terraform configurations remain modular and reusable.
5. **Main File Configuration**
    - The `main.tf` file is the central configuration file that defines and manages the **provisioning of EC2 instances and an EKS cluster** using Terraform modules.
        - `EC2 module`: Calls the `modules/ec2` module to **create EC2 instances**, passing instance types, key pair name, security group, and subnet details.
        - `EKS module`: Calls the `modules/eks` module to deploy an **EKS cluster**, passing cluster name, role, version, VPC, and subnet IDs.
    - This modular approach improves maintainability and reusability, keeping the Terraform configuration clean and structured.
6. **Output Configuration**
    - The `output.tf` file defines **output values** to display key infrastructure details after deployment. These outputs help users access important resource information.
        - `ansible_instance_id` → Fetches the **Ansible control node's** EC2 instance ID.
        - `jenkins_master_instance_id` → Retrieves the EC2 instance ID for the **Jenkins master node**.
        - `jenkins_slave_instance_id` → Retrieves the EC2 instance ID for the **Jenkins slave node**.
        - `eks_cluster_endpoint` → Displays the API **server endpoint** of the **deployed EKS cluster**.
        - `eks_cluster_arn_value` → Provides the **Amazon Resource Name (ARN)** of the **EKS cluster**.
## 4. Modules Overview
This Terraform project follows a modular structure to keep configurations organized and reusable. It consists of two primary modules:
1. EC2 Module `(modules/ec2)`

    - `main.tf` → Provisions three EC2 instances:
        - Ansible Control Node – Manages software installation on Jenkins nodes.
        - Jenkins Master Node – Hosts Jenkins for CI/CD operations.
        - Jenkins Slave Node – Acts as a Jenkins agent for job execution.
        - `File Provisioning` – Copies private keys , host file and Ansible playbooks to the Ansible node for SSH connectivity with Jenkins nodes and to install playbooks.
        - `Remote Execution`: Installs Ansible, configures SSH connections, and executes playbooks on Jenkins nodes using inline remote-exec.
    - `data.tf` → Fetches the latest Ubuntu 22.04 AMI ID from AWS owned by Canonical using **data source**.
    - `varible.tf` → Defines variables for EC2 instance types, key pair, subnet ID, and security group ID, passed from the `project's main.tf` file to modules.
    - `output.tf` → Defines EC2 module output values for Ansible, Jenkins Master, and Jenkins Slave instance IDs, passing them back to the `project's output.tf`.
    - `files/` →  The files folder contains an SSH key, an Ansible inventory file, and playbooks for installing and configuring Jenkins Master and Slave nodes.
2. EKS Module `(modules/eks)`

    - `main.tf` → Deploys an EKS cluster with cluster roles, worker node group, worker node role, and worker node security groups.
    - `varible.tf` → Defines variables for EKS cluster name, cluster roles name, version, subnet IDs, worker node group name, worker node role name, worker node instance type, key pair, security group, and VPC ID, passed from the `project's main.tf` file to modules.
    - `output.tf` → Defines EKS module output values for cluster end point and cluster arn, passing them back to the `project's output.tf`.
## 5. Usage

### Sample Usage
1. **Cloning the Repository**
    ```sh
    git clone https://github.com/saishandilya/devops-infra.git
    cd devops-infra
    ```

2. **Configuring Terraform Variables**

    Create two `.tfvars` files, `ec2.tfvars` and `eks.tfvars`, to pass values to the Terraform code. Below are the sample required parameters; replace the values with your own configuration."
    #### `ec2.tfvars`  

    ```hcl
    ansible_instance_type       =   "t2.micro"
    jenkins_instance_type       =   "t2.medium"
    instance_key_name           =   "devops-master-key"
    security_group_id           =   "sg-xxxxxxxxxxxxx"
    public_subnet_id_list       =   ["subnet-xxxxxxxxxx"]
    ```

    #### `eks.tfvars`  
    ```hcl
    cluster_name                =   "eks-devops"
    cluster_role_name           =   "eksClusterRole"
    cluster_version             =   "1.31"
    vpc_id                      =   "vpc-xxxxxxxxxxxxx"
    public_subnet_id_list       =   ["subnet-xxxxxxxxxx", "subnet-xxxxxxxxxx", "subnet-xxxxxxxxxx"]
    instance_key_name           =   "devops-master-key"
    ```

3. **EC2 Infrastructure Deployment**

    Use the following commands from your `local machine` to deploy the EC2 module for provisioning instances.
    ####  `local machine`
    1. `terraform initialize`

        ```hcl
        Command: terraform init -backend-config="key=ec2/terraform.tfstate"
        ```
    2. `terraform validate`

        ```hcl
        Command: terraform validate
        ```
    3. `terraform plan`

        ```hcl
        Command: terraform plan -target="module.ec2" -var-file="ec2.tfvars" -out=ec2plan
        ```

    4. `terraform apply`

        ```hcl
        Command: terraform apply "ec2plan"
        ```

4. **EKS Infrastructure Deployment**

    Use the following commands from `jenkins pipeline for eks` to deploy the EKS module for cluster creation.
    ####  `Jenkins pipeline`
    1. `terraform initialize`

        ```hcl
        Command: terraform init -backend-config="key=eks/terraform.tfstate"
        ```
    2. `terraform validate`

        ```hcl
        Command: terraform validate
        ```

    3. `terraform plan`

        ```hcl
        Command: terraform plan -target="module.eks" -var-file="eks.tfvars" -out=eksplan
        ```

    4. `terraform apply`

        ```hcl
        Command: terraform apply -target="module.eks" -var-file="eks.tfvars" -auto-approve
        ```

## 6. CleanUp
To ensure a clean and efficient environment, follow these steps to remove resources after usage.
1. **Destroy Terraform Resources**
    ####  `local machine`
    ```hcl
    Command: terraform destroy -target="module.ec2" -var-file="ec2.tfvars" -auto-approve
    ```

    ####  `jenkins pipeline for eks`
    ```hcl
    Command: terraform destroy -target="module.eks" -var-file="eks.tfvars" -auto-approve
    ```
2. **Delete SSH Keys**
    - Remove the SSH key from the AWS Console.

3. **Clean Up S3 Buckets**
    - Remove the S3 bucket created for logs or Terraform state, empty and delete it.

4. **Delete Terraform State Files**
    - Remove local Terraform folder and terraform.lock.hcl files, if you want a fresh start.
    ####  `local machine`
    ```sh
    rm -rf .terraform/ .terraform.lock.hcl
    ```
5. **Verify Resource Deletion**
    - Manually check in the AWS Console or run these commands.
    ####  `local machine`
    ```sh
    aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"
    aws eks list-clusters
    aws s3 ls
    ```
## 7. Conclusion
This README serves as a guide to understanding Terraform code, project structure, modules, and usage. Following it helps deploy infrastructure and grasp key Terraform concepts for secure cloud management.

Thank you for reading till the end. Return to the main [README](../README.md) file for further details.