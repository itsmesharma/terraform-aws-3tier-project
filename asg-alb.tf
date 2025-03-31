# Create a launch configuration for the Autoscalling-EC2 instances
resource "aws_launch_configuration" "public_webtier_launch_config" {
  image_id                    = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  security_groups             = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name                    = "terraformkeypair"
  user_data                   = file("userdata.sh")

  lifecycle {
    create_before_destroy = true
  }
}

# Create an Auto Scaling group for the EC2 instances
resource "aws_autoscaling_group" "public_webtier_autoscaling_group" {
  name                      = "public-webtier-asg"
  min_size                  = 2
  max_size                  = 4
  desired_capacity          = 2
  launch_configuration      = aws_launch_configuration.public_webtier_launch_config.name
  target_group_arns         = [aws_lb_target_group.web.arn]
  vpc_zone_identifier       = aws_subnet.public_webtier_subnet.*.id
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "public-instance"
    propagate_at_launch = true
  }
}

# Define a scaling policy to increase the number of instances when CPU utilization is above 80%
resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "public-webtier-scale-up-policy"
  autoscaling_group_name = aws_autoscaling_group.public_webtier_autoscaling_group.name
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "SimpleScaling"
  scaling_adjustment     = 1

  metric_aggregation_type = "Average"
}

# Define a scaling policy to decrease the number of instances when CPU utilization is below 20%
resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "public-webtier-scale-down-policy"
  autoscaling_group_name = aws_autoscaling_group.public_webtier_autoscaling_group.name
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  policy_type            = "SimpleScaling"
  scaling_adjustment     = -1

  metric_aggregation_type = "Average"

}


# Trigger the scale-up policy when CPU utilization is above 80% for 2 consecutive periods
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_scale_up" {
  alarm_name          = "public-webtier-cpu-utilization-scale-up"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 15
  alarm_description   = "Scale up the number of instances when CPU utilization is above 80% for 2 consecutive periods"
  alarm_actions       = [aws_autoscaling_policy.scale_up_policy.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.public_webtier_autoscaling_group.name
  }
}


# Trigger the scale-down policy when CPU utilization is below 20
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_scale_down" {
  alarm_name          = "public-webtier-cpu-utilization-scale-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 5
  alarm_description   = "Scale down the number of instances when CPU utilization is below 20%"
  alarm_actions       = [aws_autoscaling_policy.scale_down_policy.arn]

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.public_webtier_autoscaling_group.name
  }

}



# Create Apllication Load Balancer
resource "aws_lb" "public_webtier_loadbalancer" {
  name               = "public-webtier-loadbalancer"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.public_webtier_subnet.*.id
  security_groups    = [aws_security_group.lb_sg.id]
  tags = {
    Name = "public_webtier_loadbalancer"
  }
}

# Create a target group for the load balancer
resource "aws_lb_target_group" "web" {
  name     = "web"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.terraform_vpc.id

  health_check {
    path = "/"
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Associate the target group with the EC2 instances created by autoscaling
resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.public_webtier_autoscaling_group.name
  alb_target_group_arn   = aws_lb_target_group.web.arn
}

#listner
resource "aws_lb_listener" "web" {
  load_balancer_arn = aws_lb.public_webtier_loadbalancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.web.arn
    type             = "forward"
  }
}

