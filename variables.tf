variable "aws_account_id" {
  description = "The AWS Account ID"
  type        = string
}

variable "primary_region" {
  description = "The primary AWS region for resources."
  type        = string
  default     = "us-east-1"
}

variable "replica_region" {
  description = "The AWS region for replica resources."
  type        = string
  default     = "us-west-1"
}
