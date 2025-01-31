variable "queue_arn" {
  type = string
}

variable "queue_url" {
  type = string
}

variable "ec2_role_name" {
  type    = string
  default = "ec2-queue-poller-role"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "instance_type" {
  type    = string
  default = "t2.micro"
}

variable "docker_image" {
  type    = string
  default = "atlantisj11/queue-poller"
}

variable "app_log_group" {
  type    = string
  default = "queue-poller-logs"
}
