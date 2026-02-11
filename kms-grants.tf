#-------------------------------------------------------------------------------
# KMS key for Data Lake encryption
#-------------------------------------------------------------------------------

resource "aws_kms_key" "datalake" {
  description             = "KMS key for Data Lake S3 and Glue encryption"
  enable_key_rotation     = true
  deletion_window_in_days = 30

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowAWSServiceUsage"
        Effect = "Allow"
        Principal = {
          Service = [
            "s3.amazonaws.com",
            "glue.amazonaws.com",
            "lakeformation.amazonaws.com"
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = local.tags
}

resource "aws_kms_alias" "datalake" {
  name          = "alias/${local.name_prefix}-kms"
  target_key_id = aws_kms_key.datalake.key_id
}
