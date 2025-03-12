pipeline {

    agent { node { label 'slave' } }

    tools { terraform 'terraform' }

    environment {
        BUCKET_NAME = "<your s3 bucket name>" // e.g., s3-backend-bucket
        PLAN_NAME   = ""
    }

    parameters {
        choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Choose Terraform action to perform')
    }

    stages {
        stage('Terraform Init') {
            steps {
                echo 'Terraform Initialization...!!!'
                // Terraform initialize
                sh 'terraform init -backend-config="key=eks/terraform.tfstate"'
            }
        }

        stage('Terraform Validate') {
            steps {
                echo 'Terraform code Validation...!!!'
                // Terraform validate
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo 'Terraform Planning...!!!'
                script {
                    // Generate a unique plan name based on the current date and time
                    PLAN_NAME = "eksplan-" + sh(script: 'date +%Y%m%d-%H%M%S', returnStdout: true).trim()
                    JSON_PLAN_NAME = "${PLAN_NAME}.json"
                }
                echo "Plan Name: ${PLAN_NAME}"

                withCredentials([file(credentialsId: 'eks-tfvars', variable: 'TFVARS_FILE')]) {
                    // Run the terraform plan command and output the plan in JSON format
                    sh """
                        terraform plan -target="module.eks" -var-file="\$TFVARS_FILE" -out="${PLAN_NAME}"
                        terraform show -json ${PLAN_NAME} > ${JSON_PLAN_NAME}
                    """

                    sh "aws s3 cp ${JSON_PLAN_NAME} s3://${BUCKET_NAME}/eks-terraform-plan/"
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo 'Terraform Applying Infrastructure Plan...!!!'
                sh """
                    if [ ! -f "${PLAN_NAME}" ]; then
                        echo "ERROR: Plan file not found: ${PLAN_NAME}" >&2
                        exit 1
                    fi

                    terraform apply "${PLAN_NAME}"
                """
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.ACTION == 'destroy' }
            }
            steps {
                echo 'Terraform Destroying Infrastructure...!!!'
                withCredentials([file(credentialsId: 'eks-tfvars', variable: 'TFVARS_FILE')]) {
                    sh """
                        terraform destroy -target="module.eks" -var-file="\$TFVARS_FILE" -auto-approve
                    """
                }
            }
        }

    }
}