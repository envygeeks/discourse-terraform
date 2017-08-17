data "aws_acm_certificate" "discourse" {
  domain = "${var.discourse_hostname}"
  statuses = [
    "ISSUED"
  ]
}
