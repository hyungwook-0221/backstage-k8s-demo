variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "${{ values.region }}"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "${{ values.instance_type }}"
}

variable "ami_id" {
  description = "AMI ID to use for the instance (leave empty for latest Amazon Linux 2023)"
  type        = string
  default     = "${{ values.ami_id }}"
}

variable "enable_public_ip" {
  description = "Enable public IP assignment"
  type        = bool
  default     = ${{ values.enable_public_ip }}
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "${{ values.instance_name }}"
}
