terraform {
    backend "s3" {
    bucket          =   "terraform-statefile-s3-backend-storage"
    key             =   "" # ec2/terraform.tfstate
    region          =   "us-east-1"
    }
}