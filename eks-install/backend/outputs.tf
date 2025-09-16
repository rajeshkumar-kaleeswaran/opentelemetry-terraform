output "s3_bucket_name" {
  value       = aws_s3_bucket.terraform_state.id
  description = "The name of the S3 bucket"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.id
  description = "The name of the DynamoDB table"
}
output "instance_id" {
  value       = aws_instance.ec2_instance
  description = "The ID of the EC2 instance"
}
output "nametag" {
  value       = aws_instance.ec2_instance.tags["Name"]
  description = "The Name tag of the EC2 instance"
}
output "public_ip" {
  value       = aws_instance.ec2_instance
  description = "The public IP address of the EC2 instance"
}