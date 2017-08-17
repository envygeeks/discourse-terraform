resource "aws_route53_record" "discourse_verification" {
  zone_id = "discourse"
  name = "_amazonses.${var.discourse_hostname}"
  type = "TXT"
  ttl = "600"

  records = ["${
    aws_ses_domain_identity.discourse.verification_token
  }"]
}
