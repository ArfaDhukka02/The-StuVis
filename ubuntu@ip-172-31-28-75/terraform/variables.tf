variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "ami_id" {
  description = "Ubuntu 22.04 LTS AMI ID (region-specific)"
  type        = string
  default     = "ami-0c7217cdde317cfec" # us-east-1 Ubuntu 22.04
}

variable "public_key_path" {
  description = "Path to your SSH public key file"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "db_username" {
  description = "RDS MySQL master username"
  type        = string
  default     = "appuser"
}

variable "db_password" {
  description = "RDS MySQL master password — override via TF_VAR_db_password env var"
  type        = string
  sensitive   = true
}
