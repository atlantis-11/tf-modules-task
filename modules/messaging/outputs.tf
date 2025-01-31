output "queue_arn" {
  value = aws_sqs_queue.s3_queue.arn
}

output "queue_url" {
  value = aws_sqs_queue.s3_queue.url
}

output "queue_name" {
  value = aws_sqs_queue.s3_queue.name
}

output "dlq_name" {
  value = aws_sqs_queue.dlq.name
}
