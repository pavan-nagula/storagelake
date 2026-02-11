locals {
  name_prefix = "${var.program}-${var.environment}-datalake"

  tags = {
    program     = var.program
    environment = var.environment
    managed_by  = "terraform"
  }
}
