output "ingest_lambda_name" {
  value = aws_lambda_function.ingest_lambda.function_name
}

output "process_lambda_name" {
  value = aws_lambda_function.process_lambda.function_name
}

output "report_lambda_name" {
  value = aws_lambda_function.report_lambda.function_name
}

output "raw_data_bucket_name" {
  value = aws_s3_bucket.raw_data.bucket
}

output "reports_bucket_name" {
  value = aws_s3_bucket.reports.bucket
}
