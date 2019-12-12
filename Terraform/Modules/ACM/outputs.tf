/*
  Output Values
*/

output "acm" {
  value       = aws_acm_certificate.certificate
  description = "ACM"
}