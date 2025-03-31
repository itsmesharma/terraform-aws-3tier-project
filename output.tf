output "ami" {
  value = data.aws_ami.ubuntu.id
}

output "rds_primary_instance_endpoint" {
  value = aws_db_instance.rds_primary_instances.*.endpoint
}

output "load_balancer_dns" {
  value = aws_lb.public_webtier_loadbalancer.dns_name
}
