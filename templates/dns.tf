resource "aws_route53_record" "discourse" {
  zone_id = "discourse"
  name    = "${var.discourse_hostname}"
  type    = "CNAME"
  ttl     = "600"

  records = ["${
    aws_elb.discourse.dns_name
  }"]
}
