output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.stuvis_ec2.public_ip
}

output "ec2_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = aws_instance.stuvis_ec2.public_dns
}

output "rds_endpoint" {
  description = "RDS MySQL endpoint (host:port)"
  value       = aws_db_instance.stuvis_rds.endpoint
}

output "rds_db_name" {
  description = "RDS database name"
  value       = aws_db_instance.stuvis_rds.db_name
}
