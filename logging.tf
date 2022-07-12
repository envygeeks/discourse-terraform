resource "aws_cloudwatch_log_group" "discourse" {
  name = "${var.slug}"

  tags = {
    Stack = "${var.slug}"
    Environment = "production"
    Description = "${var.slug}"
    Application = "Discourse"
    Name = "${var.slug}"
  }
}
