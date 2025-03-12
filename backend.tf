terraform {
    backend "s3" {
    bucket          =   "<your s3 bucket name>" # e.g., s3-backend-bucket
    key             =   ""
    region          =   "<your region>" # e.g., us-east-1
    }
}