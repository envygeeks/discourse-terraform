resource "aws_vpc" "discourse" {
  enable_dns_hostnames = true
  cidr_block = "10.0.0.0/16"
  tags {
    Name = "${var.slug}"
  }
}

# --
# This is a small cluster, there is no need to get crazy
#   with our allocations, each subnet gets 255 hosts, calculated
#   we can always increase it later if we need.
# --
resource "aws_subnet" "discourse-a" {
  vpc_id = "${aws_vpc.discourse.id}"
  availability_zone = "${var.zone-a}"
  cidr_block = "10.0.0.0/24"

  tags {
    Name = "${var.slug}"
  }
}

# --
resource "aws_subnet" "discourse-b" {
  vpc_id = "${aws_vpc.discourse.id}"
  availability_zone = "${var.zone-b}"
  cidr_block = "10.0.1.0/24"

  tags {
    Name = "${var.slug}"
  }
}

# --
resource "aws_route_table" "discourse" {
  vpc_id = "${aws_vpc.discourse.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${
      aws_internet_gateway.discourse.id
    }"
  }
}

# --
resource "aws_route_table_association" "discourse" {
  route_table_id = "${aws_route_table.discourse.id}"
  subnet_id = "${
    aws_subnet.discourse-a.id
  }"
}

# --
resource "aws_internet_gateway" "discourse" {
  vpc_id = "${
    aws_vpc.discourse.id
  }"
}

# --
resource "aws_db_subnet_group" "discourse" {
  name = "${var.slug}"
  subnet_ids = [
    "${aws_subnet.discourse-a.id}",
    "${aws_subnet.discourse-b.id}"
  ]
}

# --
resource "aws_elasticache_subnet_group" "discourse" {
  name = "${var.slug}"
  subnet_ids = [
    "${aws_subnet.discourse-a.id}",
    "${aws_subnet.discourse-b.id}"
  ]
}
