variable "vpc_cidr" { default = [""] }
variable "ssh" { default = ["0.0.0.0/0"] }
variable "region" { default = "us-east-2" }
variable "rds_instance_type" { default = "db.t2.micro" }
variable "elasticache_instance_type" { default = "cache.t2.micro" }
variable "ec2_instance_type" { default = "t2.medium" }
variable "ec2_ami" { default = "ami-dbbd9dbe" }
variable "zone_a" { default = "us-east-2b" }
variable "zone_b" { default = "us-east-2c" }
variable "slug" { default = "discourse" }
variable "db_password" {}

variable "discourse_smtp_username" {}
variable "discourse_smtp_port" { default="587" }
variable "discourse_developer_emails" { default="user@example.com" }
variable "discourse_smtp_address" { default="smtp.gmail.com" }
variable "discourse_smtp_password" {}
variable "discourse_hostname" {}

data "template_file"  "discourse" {
  template = "${file("templates/remote/web.yml.tpl")}"

  vars {
    discourse_smtp_port = "${var.discourse_smtp_port}",
    discourse_smtp_username = "${var.discourse_smtp_username}",
    discourse_redis_port = "${aws_elasticache_cluster.discourse.port}",
    discourse_postgres_username = "${aws_db_instance.discourse.username}",
    discourse_redis_host = "${aws_elasticache_cluster.discourse.cache_nodes.0.address}",
    discourse_developer_emails = "${var.discourse_developer_emails}",
    discourse_postgres_host = "${aws_db_instance.discourse.address}",
    discourse_postgres_port = "${aws_db_instance.discourse.port}",
    discourse_smtp_password = "${var.discourse_smtp_password}",
    discourse_smtp_address = "${var.discourse_smtp_address}",
    discourse_postgres_password = "${var.db_password}",
    discourse_hostname = "${var.discourse_hostname}"
  }
}
