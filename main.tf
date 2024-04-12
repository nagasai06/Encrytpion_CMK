provider "aws" {
  region = var.primary_region
}

provider "aws" {
  alias  = "west"
  region = var.replica_region
}


resource "aws_kms_key" "primary_key" {
  description             = "Primary KMS Key for SNS"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.kms_policy.json
  multi_region            = true
}

resource "aws_kms_replica_key" "replica_key" {
  provider = aws.west
  primary_key_arn         = aws_kms_key.primary_key.arn
  description             = "Replica of Primary KMS Key for SNS"
  deletion_window_in_days = 10
  policy                  = data.aws_iam_policy_document.kms_policy.json
}

resource "aws_kms_alias" "primary_key_alias" {
  name          = "alias/SNSPrimaryKey"
  target_key_id = aws_kms_key.primary_key.key_id
}

resource "aws_kms_alias" "replica_key_alias" {
  name          = "alias/SNSReplicaKey"
  target_key_id = aws_kms_replica_key.replica_key.key_id
}

data "aws_iam_policy_document" "kms_policy" {
  statement {
    sid       = "Enable IAM User Permissions"
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    actions   = ["kms:*"]
    resources = ["*"]
  }

  statement {
    sid       = "Allow Key Management Actions for Specific Role"
    effect    = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.aws_account_id}:root"]
    }
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"  
    ]
    resources = ["*"]
  }
}

resource "aws_sns_topic" "SNS_primary_region" {
  name              = "SNS-primary-region"
  kms_master_key_id = aws_kms_alias.primary_key_alias.arn
}

resource "aws_sns_topic" "SNS_replica_region" {
  provider          = aws.west
  name              = "user-updates-topic-replica"
  kms_master_key_id = aws_kms_alias.replica_key_alias.arn
}
