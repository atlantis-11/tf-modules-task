variable "queue_name" {
  type = string
}

variable "dlq_name" {
  type = string
}

variable "asg_id" {
  type = string
}

variable "asg_name" {
  type = string
}

variable "asg_increase_policy_arn" {
  type = string
}

variable "asg_decrease_policy_arn" {
  type = string
}

variable "asg_messages_per_instance_scaling_threshold" {
  type    = number
  default = 100
}
