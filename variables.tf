variable "environment" {
  description = "Environment name (e.g., hyderabad, dev, prod)"
  type        = string
}

variable "region" {
  description = "AWS region for resource deployment"
  type        = string
}

variable "program" {
  description = "Program or domain owning the data lake (e.g., internal)"
  type        = string
}

variable "account_id" {
  description = "AWS account ID where the data lake is deployed"
  type        = string
}