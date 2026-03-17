# tf-module-eventbridge-scheduled-lambda
Reusable Terraform module for deploying a Lambda with execution scheduled via EventBridge

## Usage

### Minimal — local zip, auto-created role

```hcl
module "my_scheduled_lambda" {
  source = "github.com/your-org/tf-module-eventbridge-scheduled-lambda"

  name                = "my-job"
  schedule_expression = "rate(5 minutes)"
  filename            = "${path.module}/lambda.zip"
  handler             = "index.handler"
  runtime             = "python3.12"
}
```

### With environment variables and extra policies

```hcl
module "my_scheduled_lambda" {
  source = "github.com/your-org/tf-module-eventbridge-scheduled-lambda"

  name                = "my-job"
  schedule_expression = "cron(0 8 * * ? *)"  # Daily at 8am UTC
  filename            = "${path.module}/lambda.zip"
  handler             = "app.handler"
  runtime             = "python3.12"
  timeout             = 300
  memory_size         = 256

  environment_variables = {
    ENV        = "production"
    LOG_LEVEL  = "INFO"
  }

  additional_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  tags = {
    Team = "platform"
  }
}
```

### Deploy from S3 with source code hash

When deploying from S3, provide `source_code_hash` so Terraform can detect package changes and redeploy automatically. A common pattern is to hash the zip with the `filebase64sha256` function before uploading, then pass the result here.

```hcl
module "my_scheduled_lambda" {
  source = "github.com/your-org/tf-module-eventbridge-scheduled-lambda"

  name                = "my-job"
  schedule_expression = "rate(1 hour)"
  s3_bucket           = "my-deploy-bucket"
  s3_key              = "lambdas/my-job.zip"
  handler             = "index.handler"
  runtime             = "nodejs20.x"
  source_code_hash    = filebase64sha256("${path.module}/lambda.zip")
}
```

### With Lambda layers

```hcl
module "my_scheduled_lambda" {
  source = "github.com/your-org/tf-module-eventbridge-scheduled-lambda"

  name                = "my-job"
  schedule_expression = "rate(5 minutes)"
  filename            = "${path.module}/lambda.zip"
  handler             = "index.handler"
  runtime             = "python3.12"

  layers = [
    "arn:aws:lambda:us-east-1:123456789012:layer:my-deps:4",
  ]
}
```

### Bring your own IAM role

```hcl
module "my_scheduled_lambda" {
  source = "github.com/your-org/tf-module-eventbridge-scheduled-lambda"

  name                = "my-job"
  schedule_expression = "rate(15 minutes)"
  filename            = "${path.module}/lambda.zip"
  handler             = "index.handler"
  runtime             = "python3.12"
  iam_role_arn        = aws_iam_role.my_role.arn
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `name` | Name for the Lambda and associated resources | `string` | — | yes |
| `schedule_expression` | EventBridge schedule expression | `string` | — | yes |
| `handler` | Lambda handler | `string` | — | yes |
| `runtime` | Lambda runtime | `string` | — | yes |
| `filename` | Path to local zip file | `string` | `null` | no |
| `s3_bucket` | S3 bucket for deployment package | `string` | `null` | no |
| `s3_key` | S3 key for deployment package | `string` | `null` | no |
| `source_code_hash` | Base64 SHA256 of the deployment package. Computed automatically for local zips; provide this for S3 deployments to enable change detection. | `string` | `null` | no |
| `layers` | List of Lambda layer ARNs to attach (max 5) | `list(string)` | `[]` | no |
| `environment_variables` | Lambda environment variables | `map(string)` | `{}` | no |
| `timeout` | Lambda timeout (seconds) | `number` | `60` | no |
| `memory_size` | Lambda memory (MB) | `number` | `128` | no |
| `iam_role_arn` | Existing IAM role ARN to use | `string` | `null` | no |
| `additional_policy_arns` | Extra policies to attach to the created role | `list(string)` | `[]` | no |
| `enabled` | Whether the schedule is enabled | `bool` | `true` | no |
| `tags` | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `lambda_function_name` | Lambda function name |
| `lambda_function_arn` | Lambda function ARN |
| `lambda_role_arn` | IAM role ARN used by the Lambda |
| `event_rule_arn` | EventBridge rule ARN |
| `event_rule_name` | EventBridge rule name |
