locals {
  role_arn = var.iam_role_arn != null ? var.iam_role_arn : aws_iam_role.lambda[0].arn
}

# ------------------------------------------------------------------------------
# IAM — only created when no role is provided
# ------------------------------------------------------------------------------

data "aws_iam_policy_document" "lambda_assume_role" {
  count = var.iam_role_arn == null ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  count = var.iam_role_arn == null ? 1 : 0

  name               = "${var.name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  count = var.iam_role_arn == null ? 1 : 0

  role       = aws_iam_role.lambda[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = var.iam_role_arn == null ? toset(var.additional_policy_arns) : toset([])

  role       = aws_iam_role.lambda[0].name
  policy_arn = each.value
}

# ------------------------------------------------------------------------------
# Lambda
# ------------------------------------------------------------------------------

resource "aws_lambda_function" "this" {
  function_name = var.name
  role          = local.role_arn
  handler       = var.handler
  runtime       = var.runtime
  timeout       = var.timeout
  memory_size   = var.memory_size

  # Support both local zip and S3 deployment
  filename         = var.filename
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  source_code_hash = var.filename != null ? filebase64sha256(var.filename) : null

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  tags = var.tags
}

# ------------------------------------------------------------------------------
# EventBridge
# ------------------------------------------------------------------------------

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.name}-schedule"
  schedule_expression = var.schedule_expression
  state               = var.enabled ? "ENABLED" : "DISABLED"
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "${var.name}-target"
  arn       = aws_lambda_function.this.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}
