#-------------------------------------------------------------------------------
# AWS Glue Data Catalog Databases
#-------------------------------------------------------------------------------

resource "aws_glue_catalog_database" "raw" {
  name = "${var.environment}_raw"

  description = "Raw data layer for ${var.environment} data lake"

  tags = merge(
    local.tags,
    { layer = "raw" }
  )
}

resource "aws_glue_catalog_database" "processed" {
  name = "${var.environment}_processed"

  description = "Processed data layer for ${var.environment} data lake"

  tags = merge(
    local.tags,
    { layer = "processed" }
  )
}

resource "aws_glue_catalog_database" "curated" {
  name = "${var.environment}_curated"

  description = "Curated data layer for ${var.environment} data lake"

  tags = merge(
    local.tags,
    { layer = "curated" }
  )
}
