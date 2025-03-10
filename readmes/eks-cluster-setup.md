# EKS Cluster Setup Guide

## Introduction  
This guide provides a step-by-step approach to deploying an **Amazon EKS (Elastic Kubernetes Service) cluster** using **Terraform**.  
By following this guide, you will:  
✅ Provision the necessary **AWS infrastructure**  
✅ Deploy and configure the **EKS cluster**  
✅ Set up essential components for managing **containerized applications**.

## Prerequisites  
Before you begin, ensure you have the following installed: `Jenkins Slave`
- AWS CLI (Pre-installed via Ansible)  
- Terraform (installed via jenkins plugin)
- IAM permissions to create EKS resources

Follow these steps to set up AWS EKS using a Jenkins pipeline with Terraform.

### **1. IAM Role for Jenkins Slave**  
The Jenkins slave machine requires an IAM role with permissions to run the EKS deployment. 
- Create an IAM policy named `EC2_Policy_for_EKS` and attach the permissions below.
- Create an IAM role named `EC2_Role_for_EKS` and attach the created policy.
- Attach this IAM role to the Jenkins slave EC2 instance.

    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "EKSClusterManagement",
                "Effect": "Allow",
                "Action": [
                    "eks:CreateCluster",
                    "eks:CreateNodegroup",
                    "eks:DescribeCluster",
                    "eks:DescribeNodegroup",
                    "eks:ListClusters",
                    "eks:ListNodegroups",
                    "eks:TagResource",
                    "eks:UntagResource",
                    "eks:UpdateClusterConfig",
                    "eks:UpdateClusterVersion",
                    "eks:UpdateNodegroupConfig",
                    "eks:UpdateNodegroupVersion",
                    "eks:DeleteCluster",
                    "eks:DeleteNodegroup",
                    "eks:RegisterCluster",
                    "eks:DeregisterCluster",
                    "eks:DescribeClusterVersions"
                ],
                "Resource": "*"
            },
            {
                "Sid": "IAMPermissions",
                "Effect": "Allow",
                "Action": [
                    "iam:CreateRole",
                    "iam:GetRole",
                    "iam:DeleteRole",
                    "iam:PassRole",
                    "iam:ListRoles",
                    "iam:TagRole",
                    "iam:AttachRolePolicy",
                    "iam:DetachRolePolicy",
                    "iam:PutRolePolicy",
                    "iam:DeleteRolePolicy",
                    "iam:CreateInstanceProfile",
                    "iam:GetInstanceProfile",
                    "iam:ListInstanceProfiles",
                    "iam:DeleteInstanceProfile",
                    "iam:AddRoleToInstanceProfile",
                    "iam:RemoveRoleFromInstanceProfile",
                    "iam:GetPolicy",
                    "iam:ListAttachedRolePolicies",
                    "iam:ListRolePolicies",
                    "iam:ListPolicies",
                    "iam:GetRolePolicy",
                    "iam:DeletePolicy",
                    "iam:CreatePolicy",
                    "iam:UpdateRole",
                    "iam:ListInstanceProfilesForRole"
                ],
                "Resource": "*"
            },
            {
                "Sid": "EC2SecurityGroupManagement",
                "Effect": "Allow",
                "Action": [
                    "ec2:CreateSecurityGroup",
                    "ec2:DescribeSecurityGroups",
                    "ec2:DescribeTags",
                    "ec2:DeleteSecurityGroup",
                    "ec2:AuthorizeSecurityGroupIngress",
                    "ec2:AuthorizeSecurityGroupEgress",
                    "ec2:RevokeSecurityGroupIngress",
                    "ec2:RevokeSecurityGroupEgress",
                    "ec2:CreateTags",
                    "ec2:DescribeInstances",
                    "ec2:DescribeVpcs",
                    "ec2:DescribeSubnets",
                    "ec2:DescribeKeyPairs",
                    "ec2:DescribeNetworkInterfaces"
                ],
                "Resource": "*"
            },
            {
                "Sid": "S3TerraformStateBucket",
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObject",
                    "s3:GetObjectTagging",
                    "s3:ListBucket",
                    "s3:DeleteObject",
                    "s3:GetObjectVersion"
                ],
                "Resource": [
                    "arn:aws:s3:::<your terraform backend s3 bucket>",
                    "arn:aws:s3:::<your terraform backend s3 bucket>/*"
                ]
            }
        ]
    }
    ```

### **2. Jenkins Pipeline Configuration**
- Go to the **Jenkins Dashboard**, click **New Item**, enter the **Item Name** (e.g., `eks-cluster-infra`), select **Pipeline** and click **OK**.
- In the **Configure**, select the **General**, provide a **Description** (e.g., `Jenkins pipeline to deploy AWS EKS cluster using Terraform`), enable **Discard Old Builds**, set **Days to Keep Builds** (e.g., `7`), and **Max # of Builds to Keep** (e.g., `5`).
- In the **Pipeline** section, set **Definition** to `Pipeline Script` and inside **Script** select `Hello World` from the dropdown.
- Click **Apply & Save**.
- Navigate to **Manage Jenkins → Tools**, Scroll down to **Terraform installations** and click `Add Terraform`, Provide a **Name** (e.g., `terraform`), Check the box for **Install automatically**, Select the **latest Linux AMD version** (e.g., `Terraform 1.5.0 Linux (amd64)`) and Click **Apply & Save**. 

### **3. Creating Pipeline Stages**
0. **Prerequisites**
    - **Clone the repository** to your local machine.
        ```sh
        git clone https://github.com/saishandilya/devops-infra.git
        cd devops-infra
        ```
    - Update the `backend.tf` file with <**your S3 bucket name**> and <**region**>.
        ```hcl
        terraform {
            backend "s3" {
            bucket          =   "<your s3 bucket name>" # e.g., s3-backend-bucket
            key             =   "" # value will be passed dynamically.
            region          =   "<your region>" # e.g., us-east-1
            }
        }
        ```
    - **Push** the changes to **your GitHub repository**.
    - Alternatively, **fork the repository**, update the `backend.tf` file on the console, and push it to your forked repository.
1. **Checkout Stage:**
    -  In the **Pipeline** section, click **Pipeline Syntax**, search for **Git**, enter the **Repository URL** (`https://github.com/<your user name>/devops-infra.git`), select **Branch** as `main`, set **Credentials** to `None`, generate the **Pipeline Script**, copy the generated code, and replace it in the **checkout stage**.  
    -  The `tools` section fetches the Terraform path from the previously configured step. 
    -  Copy the below code and replace the HelloWorld Code: 
        ```groovy
        pipeline {

            agent { node { label 'slave' } }

            tools { terraform 'terraform' }

            stages {
                stage('Checkout') {
                    steps {
                        echo 'Fetching Infra code from GitHub'
                        git branch: 'main', url: 'https://github.com/<your user name>/devops-infra.git'
                    }
                }
            }
        }
        ```

2. **Terraform Init Stage** 
    - Copy the below provided code and add it as a **new stage** in the Pipeline, this stage initializes a Terraform working directory.
    - Setting the **WORKDIR** in `environment` section which Terraform should execute **init, plan, apply, and destroy.**
        ```groovy
        environment {
            WORKDIR = <your pipeline name> # (e.g.,'eks-infra-using-pipeline')
        }
        ```
        #### `Terraform Init Stage`
        ```groovy
        stage('Terraform Init') {
            steps {
                echo 'Terraform Initiation...!!!'
                dir("${WORKDIR}") {
                    sh 'terraform init -backend-config="key=eks/terraform.tfstate"'                    
                }
            }
        }
        ```

3. **Terraform Validate Stage** 
    - Copy the below provided code and add it as a **new stage** in the Pipeline, this stage validates the Terraform code.
        #### `Terraform Validate Stage`
        ```groovy
        stage('Terraform Validate') {
            steps {
                echo 'Terraform code Validation...!!!'
                dir("${WORKDIR}") {
                    sh 'terraform validate'
                }
            }
        }
        ```

4. **Terraform Plan Stage**
    - Create a **eks.tfvars** file and define your variables as needed.  

        #### `eks.tfvars`  
        ```hcl
        cluster_name                =   "eks-devops"
        cluster_role_name           =   "eksClusterRole"
        cluster_version             =   <latest version> (e.g.,"1.31")
        vpc_id                      =   "vpc-xxxxxxxxxxxxx"
        public_subnet_id_list       =   <list of subnets> (e.g., ["subnet-xxxxxxxxxx", "subnet-xxxxxxxxxx", "subnet-xxxxxxxxxx"])
        instance_key_name           =   "devops-master-key"
        ```
    - Go to **Manage Jenkins → Manage Credentials**, select **Global**, and click **Add Credentials**.
        - Select **Kind**: **Secret File** and provide the following details:
        - **File**: `choose file` (upload the eks.tfvars)
        - **ID**: `eks-tfvars`  
        - **Description**: EKS Cluster infra .tfvars variables file
        - Click **Create**.
    - Copy the code below and add it as a **new stage** in the pipeline. This stage plans the Terraform code to create the EKS infrastructure, generates a plan file, and copies `eks.plan` to an S3 bucket.
    - Copy the code below and add it `environment` section. This helps storing plan in the S3 Bucket.
        ```groovy
        environment {
            BUCKET_NAME = '<your terraform backend s3 bucket>' # (e.g., s3-backend-bucket)
        }
        ```
    - Add a `parameters` section to enable `Build with Parameters` in the pipeline, allowing users to decide which **actions** to perform during the build.
        ```groovy
        parameters {
            choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose Terraform action to perform')
        }
        ```

        #### `Terraform Plan Stage`
        ```groovy
        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo 'Terraform Planning...!!!'
                dir("${WORKDIR}") {
                    script {
                        env.PLAN_NAME = "eksplan-" + sh(script: 'date +%Y%m%d-%H%M%S', returnStdout: true).trim()
                    }
                    echo "${env.PLAN_NAME}"
                    withCredentials([file(credentialsId: 'eks-tfvars', variable: 'TFVARS_FILE')]) {
                        sh """
                            terraform plan -target="module.eks" -var-file="\$TFVARS_FILE" -out="${env.PLAN_NAME}"
                        """
                        sh "aws s3 cp ${env.PLAN_NAME} s3://${BUCKET_NAME}/terraform-plan/"
                    }
                }
            }
        }
        ```

5. **Terraform Apply Stage**
    - Copy the code below and add it as a **new stage** in the pipeline. This stage validates whether a valid plan exists and applies it to build the infrastructure; otherwise, it exits the pipeline.
        #### `Terraform Apply Stage`
        ```groovy
        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo 'Terraform Applying Infrastructure Plan...!!!'
                dir("${WORKDIR}") {
                    sh """
                        if [ ! -f "${env.PLAN_NAME}" ]; then
                            echo "ERROR: Plan file not found: ${env.PLAN_NAME}" >&2
                            exit 1
                        fi

                        terraform apply -target="module.eks" -auto-approve "${env.PLAN_NAME}"
                    """
                }
            }
        }
        ```
6. **Terraform Destroy Stage**
    - Copy the code below and add it as a **new stage** in the pipeline. This stage is an optional stage this destroys the entire created infrastructure.
        #### `Terraform Destroy Stage`
        ```groovy
        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                echo 'Terraform Destroying Infrastructure...!!!'
                dir("${WORKDIR}") {
                    withCredentials([file(credentialsId: 'eks-tfvars', variable: 'TFVARS_FILE')]) {
                        sh """
                            terraform destroy -target="module.eks" -var-file="\$TFVARS_FILE" -auto-approve
                        """
                    }
                }
            }
        }
        ```

### **4. Jenkinsfile and Webhook Configuration** (Need to add a webhook)

1. **Running the Pipeline Directly in Jenkins**  
- After adding all the above stages to the pipeline, **Validate** the pipeline script and check for any **syntax issues**.  
- Click **Save & Apply**.  
- Run the pipeline by clicking **Build with Parameters**. Choose **apply** to create resources or **destroy** to delete them.  

2. **Using a Jenkinsfile from GitHub**  
- Copy the pipeline stages into a **Jenkinsfile** and push it to your `GitHub repository`. Alternatively, update the existing `Jenkinsfile` in the cloned infra repository by replacing it with your custom values.  
- In Jenkins, navigate to the **Pipeline** section and set **Definition** to `Pipeline Script from SCM`.  
- Select **SCM** as **Git** and provide the following details:  
  - **Repository URL**: `<your GitHub repository URL>`  
  - **Credentials**: `<your Git credentials>`  
  - **Branches to Build**: `main`  
- Click **Apply & Save**. 

3. **Webhook Configuration**
    - Go to your GitHub **application repository**, click on `Settings`, scroll down to `Code and Automation`, select `Webhooks`, click `Add webhook`, and enter the **required password**.
    - In the `Webhook Configuration` Page, provide the following details:
        - Payload URL: `http://<jenkins-master-public-ip>:8080/github-webhook/`
        - Content type: `application/json`
        - Secret: `Null` **(Leave it empty unless you have a specific secret key)**
        - SSL Verification: `Enable SSL verification`
        - Trigger Events: `Select Just the push event`
        - Click **Add Webhook** to save the configuration.
    - Navigate to the **Jenkins Dashboard**, select the **Pipeline Job**, go to `Configure`, scroll down to `Build Triggers`, check the box for `GitHub hook trigger for GITScm polling`, then click **Apply and Save**.

## **Conclusion**  

Congratulations! 🎉 You have successfully automated the deployment of an **EKS Cluster** using a **Jenkins pipeline with Terraform**.  

- The infrastructure creation process may take **15-20 minutes** to complete.  
- Once the deployment is finished, you can proceed with **managing containerized applications** in the **Application Setup** section.  

Happy automating! 🚀  


