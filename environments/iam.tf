#-------------------------------------------------------------------------------
# Data Lake Admin Role (Lake Formation administrator)
#-------------------------------------------------------------------------------

data "aws_iam_policy_document" "datalake_admin_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.account_id}:root"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "datalake_admin" {
  name               = "${local.name_prefix}-admin-role"
  description        = "Data Lake administrator role for Lake Formation"
  assume_role_policy = data.aws_iam_policy_document.datalake_admin_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "datalake_admin_lf" {
  role       = aws_iam_role.datalake_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AWSLakeFormationDataAdmin"
}

resource "aws_iam_role_policy_attachment" "datalake_admin_glue" {
  role       = aws_iam_role.datalake_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AWSGlueConsoleFullAccess"
}

resource "aws_iam_role_policy_attachment" "datalake_admin_s3" {
  role       = aws_iam_role.datalake_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

#-------------------------------------------------------------------------------
# AWS Glue Service Role
#-------------------------------------------------------------------------------

data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "glue_service_role" {
  name               = "${local.name_prefix}-glue-role"
  description        = "Glue service role for Data Lake platform"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "glue_service_managed_policy" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "glue_s3_access" {
  role       = aws_iam_role.glue_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}
