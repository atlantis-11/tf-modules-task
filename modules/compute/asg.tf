resource "tls_private_key" "server" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "server" {
  public_key = tls_private_key.server.public_key_openssh
}

data "aws_ami" "latest_al2023" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023.6.*-x86_64"]
  }
}

resource "aws_launch_template" "queue_poller" {
  image_id      = data.aws_ami.latest_al2023.id
  instance_type = var.instance_type
  iam_instance_profile {
    name = aws_iam_instance_profile.profile.name
  }
  vpc_security_group_ids = [aws_security_group.sg.id]
  key_name               = aws_key_pair.server.key_name

  user_data = base64encode(<<-EOF
  #!/bin/bash

  yum update -y
  yum install -y docker

  systemctl start docker
  systemctl enable docker

  REGION=$(ec2-metadata --region | grep -Po 'region: \K.*')

  docker run \
      --log-driver=awslogs \
      --log-opt awslogs-region=$REGION \
      --log-opt awslogs-group=${var.app_log_group} \
      --log-opt awslogs-create-group=true \
      -e AWS_DEFAULT_REGION=$REGION \
      -e QUEUE_URL='${var.queue_url}' \
      --restart=always -d \
    ${var.docker_image}
  EOF
  )
}

resource "aws_autoscaling_group" "queue_pollers" {
  vpc_zone_identifier = aws_subnet.public_subnets[*].id
  max_size            = 3
  min_size            = 1
  enabled_metrics     = ["GroupInServiceInstances"]

  launch_template {
    id      = aws_launch_template.queue_poller.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "increase" {
  name                   = "increase"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.queue_pollers.name
  policy_type            = "SimpleScaling"
}

resource "aws_autoscaling_policy" "decrease" {
  name                   = "decrease"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.queue_pollers.name
  policy_type            = "SimpleScaling"
}
