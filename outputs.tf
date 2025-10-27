output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "asg_name" {
  value = aws_autoscaling_group.web_asg.name
}

output "alb_dns_name" {
  value = aws_alb.web-alb.dns_name
} 

output "alb_url" {
  value = "http://${aws_alb.web-alb.dns_name}"
}