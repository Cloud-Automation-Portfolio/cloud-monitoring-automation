output "lambda_arn" {
  value = aws_lambda_function.alert_hub.arn
}

output "apigw_arn" {
  value = aws_api_gateway_rest_api.alert_api.execution_arn
}

output "sns_topic_arn" {
  value = aws_sns_topic.alerts.arn
}

output "kms_key_arn" {
  value = aws_kms_key.alert_key.arn
}

output "cloudwatch_alarm_arn" {
  value = aws_cloudwatch_metric_alarm.cpu_high.arn
}
