resource "aws_ses_domain_identity" "discourse" {
  domain = "${
    var.discourse_hostname
  }"
}
