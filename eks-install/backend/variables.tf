# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"  # us east-1

}
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-0360c520857e3138f"  # Ubuntu 22.04 in us-east-1
  
}
variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "terraform-ec2-instance"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"  # my sandbox eligible instance type
}

variable "key_name" {
  description = "Name for the key pair"
  type        = string
  default     = "terraform-ec2-key"
}