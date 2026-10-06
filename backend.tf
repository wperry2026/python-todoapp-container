terraform {
  backend "s3" {
    bucket  = "psccorp-terraform-state-543569"
    key     = "prod/terraform.tfstate"
    region  = "ap-southeast-4"
    encrypt = true

    # Enable S3 Native State Locking
    use_lockfile = true
  }
}
