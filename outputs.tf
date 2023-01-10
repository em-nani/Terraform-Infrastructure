output "instance_id" {
    value       = aws_instance.tf-netvrk.id
}

output "instance_arn" {
  value       = aws_instance.tf-netvrk.arn
}

output "capacity_reservation_specification" {
  value       = aws_instance.tf-netvrk.capacity_reservation_specification
}

output "instance_state" {
  value       = aws_instance.tf-netvrk.instance_state
}

output "public_ip" {
  value       = aws_instance.tf-netvrk.public_ip
}

output "private_ip" {
  value       = aws_instance.tf-netvrk.private_ip
}

output "aws_db_instance" {
  value = aws_db_instance.tf-netvrkdb
  sensitive = true
}

output "rds_port" {
  value = "aws_rds_cluster_instance.default"
  sensitive = true
}

output "aws_vpc" {
  value = aws_vpc.my_vpc
}