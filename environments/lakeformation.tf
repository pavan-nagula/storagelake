resource "aws_lakeformation_data_lake_settings" "this" {
  admins = [
    aws_iam_role.datalake_admin.arn
  ]
}

resource "aws_lakeformation_resource" "raw" {
  arn = aws_s3_bucket.raw.arn
}

resource "aws_lakeformation_resource" "processed" {
  arn = aws_s3_bucket.processed.arn
}

resource "aws_lakeformation_resource" "curated" {
  arn = aws_s3_bucket.curated.arn
}
