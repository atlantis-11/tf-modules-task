data "aws_region" "current" {}

resource "aws_cloudwatch_metric_alarm" "queue_depth" {
  alarm_name = "queue-depth"

  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace   = "AWS/SQS"
  dimensions = {
    QueueName = var.queue_name
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"

  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 100
}

resource "aws_cloudwatch_metric_alarm" "asg_cpu_utilization" {
  alarm_name = "asg-cpu-utilization"

  metric_name = "CPUUtilization"
  namespace   = "AWS/EC2"
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"

  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 80
}

resource "aws_cloudwatch_metric_alarm" "failed_queue_processing" {
  alarm_name = "failed-queue-processing"

  metric_name = "ApproximateNumberOfMessagesVisible"
  namespace   = "AWS/SQS"
  dimensions = {
    QueueName = "${var.queue_name}-failed"
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"

  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = 5
}

resource "aws_cloudwatch_metric_alarm" "messages_per_instance_action_increase" {
  alarm_name          = "messages-per-instance-action-increase"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  threshold           = var.asg_messages_per_instance_scaling_threshold
  alarm_description   = "Add a new instance when messages per instance is above the threshold"

  alarm_actions = [var.asg_increase_policy_arn]

  metric_query {
    id          = "mpi"
    expression  = "m1/m2"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      dimensions = {
        QueueName = var.queue_name
      }

      stat   = "Average"
      period = 60
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "GroupInServiceInstances"
      namespace   = "AWS/AutoScaling"
      dimensions = {
        AutoScalingGroupName = var.asg_id
      }

      stat   = "Average"
      period = 60
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "messages_per_instance_action_decrease" {
  alarm_name          = "messages-per-instance-action-decrease"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  threshold           = var.asg_messages_per_instance_scaling_threshold
  alarm_description   = "Delete an instance when messages per instance is below the threshold"

  alarm_actions = [var.asg_decrease_policy_arn]

  metric_query {
    id          = "mpi"
    expression  = "m1/m2"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "ApproximateNumberOfMessagesVisible"
      namespace   = "AWS/SQS"
      dimensions = {
        QueueName = var.queue_name
      }

      stat   = "Average"
      period = 60
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "GroupInServiceInstances"
      namespace   = "AWS/AutoScaling"
      dimensions = {
        AutoScalingGroupName = var.asg_id
      }

      stat   = "Average"
      period = 60
    }
  }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "my-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            [
              "AWS/EC2",
              "CPUUtilization",
              "AutoScalingGroupName",
              var.asg_name
            ]
          ]
          period = 60
          stat   = "Average"
          region = data.aws_region.current.name
          title  = "ASG CPU Usage"
        }
      },
      {
        type = "alarm"
        properties = {
          alarms = [
            aws_cloudwatch_metric_alarm.messages_per_instance_action_increase.arn,
            aws_cloudwatch_metric_alarm.messages_per_instance_action_decrease.arn
          ]
          title = "Scaling alarms"
        }
      }
    ]
  })
}
