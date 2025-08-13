variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "project" {
  description = "Project slug"
  type        = string
  default     = "cma"
}

variable "slack_webhook_param_name" {
  description = "SSM parameter name for Slack webhook"
  type        = string
  default     = "/cma/slack_webhook"
}

variable "signing_key_param_name" {
  description = "SSM parameter name for webhook signing key"
  type        = string
  default     = "/cma/signing_key"
}
