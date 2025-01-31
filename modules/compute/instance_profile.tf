data "aws_iam_policy_document" "trust_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "ec2_permissions" {
  statement {
    effect = "Allow"

    actions   = ["sqs:ReceiveMessage", "sqs:DeleteMessage"]
    resources = [var.queue_arn]
  }

  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_role" "ec2" {
  name               = var.ec2_role_name
  assume_role_policy = data.aws_iam_policy_document.trust_policy.json
}

resource "aws_iam_role_policy" "ec2" {
  role   = aws_iam_role.ec2.name
  policy = data.aws_iam_policy_document.ec2_permissions.json
}

resource "aws_iam_instance_profile" "profile" {
  role = aws_iam_role.ec2.name
}
