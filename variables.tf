variable "name" {
  description = "Name for the Lambda function and associated resources"
  type        = string
}

variable "schedule_expression" {
  description = "EventBridge schedule expression (e.g. 'rate(5 minutes)' or 'cron(0 12 * * ? *)')"
  type        = string
}

variable "filename" {
  description = "Path to the Lambda deployment package zip"
  type        = string
  default     = null
}

variable "s3_bucket" {
  description = "S3 bucket containing the Lambda deployment package"
  type        = string
  default     = null
}

variable "s3_key" {
  description = "S3 key of the Lambda deployment package"
  type        = string
  default     = null
}

variable "handler" {
  description = "Lambda function handler (e.g. 'index.handler')"
  type        = string
}

variable "runtime" {
  description = "Lambda runtime (e.g. 'python3.12', 'nodejs20.x')"
  type        = string
}

variable "environment_variables" {
  description = "Environment variables to set on the Lambda function"
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "iam_role_arn" {
  description = "ARN of an existing IAM role to use for the Lambda. If not provided, a basic execution role will be created."
  type        = string
  default     = null
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the created Lambda execution role. Only used when iam_role_arn is not provided."
  type        = list(string)
  default     = []
}

variable "layers" {
  description = "List of Lambda layer ARNs to attach (max 5)"
  type        = list(string)
  default     = []
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package. Used to force redeployment when the package changes. For local zips this is computed automatically; supply this when deploying from S3."
  type        = string
  default     = null
}

variable "enabled" {
  description = "Whether the EventBridge schedule rule is enabled"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
