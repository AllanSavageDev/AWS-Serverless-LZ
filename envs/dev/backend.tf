terraform {
  backend "s3" {
    bucket         = "t5-allan-terraform-state"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "t5-allan-tf-locks"
    encrypt        = true
  }
}
