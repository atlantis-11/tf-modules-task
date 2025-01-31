output "private_key" {
  value     = tls_private_key.server.private_key_openssh
  sensitive = true
}

output "asg_id" {
  value = aws_autoscaling_group.queue_pollers.id
}

output "asg_name" {
  value = aws_autoscaling_group.queue_pollers.name
}

output "asg_increase_policy_arn" {
  value = aws_autoscaling_policy.increase.arn
}

output "asg_decrease_policy_arn" {
  value = aws_autoscaling_policy.decrease.arn
}
