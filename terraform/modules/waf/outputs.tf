output "web_acl_arn" {
  description = "ARN of the WAF web ACL (empty when WAF is disabled)."
  value       = var.enable_waf ? aws_wafv2_web_acl.this[0].arn : null
}

output "web_acl_id" {
  description = "ID of the WAF web ACL (empty when WAF is disabled)."
  value       = var.enable_waf ? aws_wafv2_web_acl.this[0].id : null
}
