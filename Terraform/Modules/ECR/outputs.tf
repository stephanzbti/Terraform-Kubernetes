/*
  Output Values
*/

output "ecr_frontend" {
  value       = aws_ecr_repository.ecr_frontend.repository_url
  description = "ECR FrontEnd Repository Name"
}

output "ecr_backend" {
  value       = aws_ecr_repository.ecr_backend.repository_url
  description = "ECR BackEnd Repository Name"
}