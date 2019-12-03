/*
  Output Values
*/

output "resource_record_name" {
  value       = aws_acm_certificate.certificate.domain_validation_options.0.resource_record_name
  description = "ACM - Record Name"
}

output "resource_record_value" {
  value       = aws_acm_certificate.certificate.domain_validation_options.0.resource_record_value
  description = "ACM - Record Value"
}