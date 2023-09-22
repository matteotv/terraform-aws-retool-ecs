output "deployment_name" {
  value = var.deployment_name
}

output "aws_lb" {
  value = aws_lb.this
}

output "domain" {
  value = var.domain
}

output "endpoint" {
  value = var.endpoint
}

output "fqdn" {
  value = aws_route53_record.endpoint.fqdn
}

output "certificate_arn" {
  value = aws_acm_certificate.this.arn
}