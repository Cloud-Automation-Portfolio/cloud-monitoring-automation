resource "aws_kms_key" "alert_key" {
  description             = "${var.project} KMS key for alert encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

resource "aws_sns_topic" "alerts" {
  name              = "${var.project}-alerts"
  kms_master_key_id = aws_kms_key.alert_key.arn
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.project}-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "alert_hub" {
  function_name    = "${var.project}-alert-hub"
  role             = aws_iam_role.lambda_role.arn
  handler          = "index.lambda_handler"
  runtime          = "python3.11"
  filename         = "${path.module}/lambda.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda.zip")

  environment {
    variables = {
      SLACK_WEBHOOK = var.slack_webhook_param_name
      SIGNING_KEY   = var.signing_key_param_name
    }
  }
}

resource "aws_api_gateway_rest_api" "alert_api" {
  name        = "${var.project}-alert-api"
  description = "API Gateway for ${var.project} alerts"
}

resource "aws_api_gateway_resource" "alerts" {
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  parent_id   = aws_api_gateway_rest_api.alert_api.root_resource_id
  path_part   = "alerts"
}

resource "aws_api_gateway_method" "post_alert" {
  rest_api_id   = aws_api_gateway_rest_api.alert_api.id
  resource_id   = aws_api_gateway_resource.alerts.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.alert_api.id
  resource_id             = aws_api_gateway_resource.alerts.id
  http_method             = aws_api_gateway_method.post_alert.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.alert_hub.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alert_hub.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.alert_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "alert_deployment" {
  depends_on  = [aws_api_gateway_integration.lambda_integration]
  rest_api_id = aws_api_gateway_rest_api.alert_api.id
  stage_name  = "prod"
}

# Simple EC2 CPU alarm (demo only, replace with real metrics later)
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${var.project}-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]
}
