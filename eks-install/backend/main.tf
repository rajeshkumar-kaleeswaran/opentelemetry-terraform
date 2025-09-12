provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "project_instance" {
  ami           = "ami-0360c520857e3138f" # ubuntu AMI (HVM), SSD Volume Type
  instance_type = "t2.medium"
  associate_public_ip_address = true
  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  tags = {
    Name = "MyProjectInstance"
  }
}
resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-project-terraform-eks-state-s3-bucket"

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "my-project-terraform-eks-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
