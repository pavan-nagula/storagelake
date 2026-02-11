provider "aws" {
  region = var.region

  default_tags {
    tags = {
      program     = var.program
      environment = var.environment
      managed_by  = "terraform"
    }
  }
}