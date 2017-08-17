resource "aws_iam_server_certificate" "discourse" {
  name = "discourse_private_certificate"
  certificate_body = "${file("keys/ssl.crt")}"
  private_key = "${file("keys/ssl.key")}"
}
