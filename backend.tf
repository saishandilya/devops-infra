terraform {
    backend "s3" {
    bucket          =   "<your s3 bucket name>" # e.g., s3-backend-bucket
    key             =   "" # e.g.,ec2/terraform.tfstate
    region          =   "<your region>" # e.g., us-east-1
    }
}