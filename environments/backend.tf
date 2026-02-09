terraform {
  backend "s3" {
    bucket               = "cats-pub-terraform-remote-backend-state"
    key                  = "terraform.tfstate"
    region               = "us-west-2"
    workspace_key_prefix = "terraform-cats-pub-hyderabad-ods/datalake/tfstates"
    dynamodb_table       = "cats-pub-terraform-remote-backend-436812234045"
    assume_role = {
      role_arn    = "arn:aws:iam::436812234045:role/TerraformRemoteStateRol"
      max_retries = 3
    }
  }
}
