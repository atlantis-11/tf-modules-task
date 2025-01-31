data "aws_iam_policy_document" "allow_s3" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }

    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.s3_queue.arn]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [var.bucket_arn]
    }
  }
}

resource "aws_sqs_queue" "s3_queue" {
  name                       = var.queue_name_base
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 30
  message_retention_seconds  = 345600

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 3
  })
}

resource "aws_sqs_queue_policy" "s3_queue" {
  queue_url = aws_sqs_queue.s3_queue.url
  policy    = data.aws_iam_policy_document.allow_s3.json
}

resource "aws_sqs_queue" "dlq" {
  name = "${var.queue_name_base}-failed"
}

resource "aws_sqs_queue_redrive_allow_policy" "dlq" {
  queue_url = aws_sqs_queue.dlq.url

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.s3_queue.arn]
  })
}
