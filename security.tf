resource "aws_key_pair" "discourse_user" {
  key_name = "discourse_user"
  public_key = "${
    file("keys/user.pub")
  }"
}

resource "aws_key_pair" "discourse_deploy" {
  key_name = "discourse_deploy"
  public_key = "${
    file("keys/deploy.pub")
  }"
}

# --
resource "aws_security_group" "discourse_public" {
  name = "${var.slug}_public"
  vpc_id = "${aws_vpc.discourse.id}"
  description = "${var.slug}"

  ingress {
    from_port = 1
    protocol = "TCP"
    to_port = 65535
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.slug}"
    Description = "${var.slug}"
    Stack = "${var.slug}"
  }
}


# --
resource "aws_security_group" "discourse_ssh" {
  description = "${var.slug}"
  vpc_id = "${aws_vpc.discourse.id}"
  name = "${var.slug}_ssh"

  # --
  # Really you should't even allow SSH by default, it
  #   should probably be disabled and enabled on a need-be
  #   basis so that you can keep it locked down.
  # --
  ingress {
    from_port = 22
    protocol = "TCP"
    to_port = 22
    cidr_blocks = "${var.ssh}"
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.slug}"
    Description = "${var.slug}"
    Stack = "${var.slug}"
  }
}

# --
resource "aws_security_group" "discourse_http" {
  description = "${var.slug}"
  vpc_id = "${aws_vpc.discourse.id}"
  name = "${var.slug}_http"

  ingress {
    from_port = 443
    protocol = "TCP"
    to_port = 443
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.slug}"
    Description = "${var.slug}"
    Stack = "${var.slug}"
  }
}

# --
resource "aws_security_group" "discourse_internal" {
  description = "${var.slug}"
  vpc_id = "${aws_vpc.discourse.id}"
  name = "${var.slug}_private"

  ingress {
    from_port = 8
    protocol = "icmp"
    to_port = 0
    cidr_blocks = [
      "10.0.0.0/24",
      "10.0.1.0/24"
    ]
  }

  ingress {
    from_port = 0
    protocol = "icmp"
    to_port = 0
    cidr_blocks = [
      "10.0.0.0/24",
      "10.0.1.0/24"
    ]
  }

  ingress {
    from_port = 1
    protocol = "TCP"
    to_port = 65535
    cidr_blocks = [
      "10.0.0.0/24",
      "10.0.1.0/24"
    ]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.slug}"
    Description = "${var.slug}"
    Stack = "${var.slug}"
  }
}

# --
resource "aws_security_group" "discourse_internal_http" {
  vpc_id = "${aws_vpc.discourse.id}"
  name = "${var.slug}_internal_http"
  description = "${var.slug}"

  ingress {
    from_port = 443
    protocol = "TCP"
    to_port = 443
    cidr_blocks = [
      "10.0.0.0/24",
      "10.0.1.0/24"
    ]
  }

  ingress {
    from_port = 80
    protocol = "TCP"
    to_port = 80
    cidr_blocks = [
      "10.0.0.0/24",
      "10.0.1.0/24"
    ]
  }

  egress {
    from_port = 0
    protocol = "-1"
    to_port = 0
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }

  tags = {
    Name = "${var.slug}"
    Description = "${var.slug}"
    Stack = "${var.slug}"
  }
}
