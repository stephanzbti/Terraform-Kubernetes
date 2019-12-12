/*
    Outputs
*/

output "gateways" {
    value       = aws_nat_gateway.gw
    description = "Nat Gateways - Object"
}