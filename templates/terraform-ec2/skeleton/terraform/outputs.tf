output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.main.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2_sg.id
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.main.ami
}

output "instance_state" {
  description = "Current state of the EC2 instance"
  value       = aws_instance.main.instance_state
}

output "web_url" {
  description = "URL to access the web server"
  value       = var.enable_public_ip ? "http://${aws_instance.main.public_ip}" : "Not accessible (no public IP)"
}
