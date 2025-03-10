terraform {
    backend "s3" {
    bucket          =   "infra-backend-statefile " # e.g., s3-backend-bucket
    key             =   "" # e.g.,ec2/terraform.tfstate
    region          =   "us-east-1" # e.g., us-east-1
    }
}