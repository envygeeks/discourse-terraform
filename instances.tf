resource "aws_instance" "discourse-1" {
  associate_public_ip_address = true
  instance_type = "${var.ec2_instance_type}"
  key_name = "${aws_key_pair.discourse_terraform.key_name}"
  subnet_id = "${aws_subnet.discourse-a.id}"
  availability_zone = "${var.zone-a}"
  ami = "${var.ec2_ami}"

  vpc_security_group_ids = [
    "${aws_security_group.discourse_ssh.id}",
    "${aws_security_group.discourse_internal_http}"
  ]

  tags {
    Name = "${var.slug}"
    role = "${var.slug}"
  }

  root_block_device {
    volume_size = "48"
  }

  # --
  # We use agent=false because
  #   1.) It doesn't support SSH-Agent proper, Yubikey fails.
  #   2.) If you use a file there is a bug: hashicorp/terraform#2983
  #   3.) This is also a problem on Windows.
  # --

  provisioner "file" {
    source = "keys/user.pub"
    destination = "~/.ssh/user.pub"
    connection {
      agent = false
      user = "ubuntu"
      type = "ssh"
      private_key = "${
        file("keys/deploy.key")
      }"
    }
  }

  # --
  provisioner "remote-exec" {
    connection {
      agent = false
      user = "ubuntu"
      type = "ssh"
      private_key = "${
        file("keys/deploy.key")
      }"
    }

    inline = [
      "cat ~/.ssh/user.pub >> ~/.ssh/authorized_keys"
    ]
  }

  # --
  provisioner "file" {
    destination = "~/setup.sh"
    source = "script/remote/setup.sh"
    connection {
      agent = false
      user = "ubuntu"
      type = "ssh"
      private_key = "${
        file("keys/deploy.key")
      }"
    }
  }

  # --
  provisioner "file" {
    content = "${data.template_file.discourse.rendered}"
    destination = "~/web.yml"
    connection {
      agent = false
      user = "ubuntu"
      type = "ssh"
      private_key = "${
        file("keys/deploy.key")
      }"
    }
  }

  # --
  provisioner "remote-exec" {
    connection {
      agent = false
      user = "ubuntu"
      type = "ssh"
      private_key = "${
        file("keys/deploy.key")
      }"
    }

    inline = [
      "bash ~/setup.sh"
    ]
  }

  # --
  provisioner "local-exec" {
    command = "echo ${aws_instance.discourse-1.public_dns}"
  }
}

# --
resource "aws_elasticache_cluster" "discourse" {
  engine = "redis"
  cluster_id = "${var.slug}"
  subnet_group_name = "${aws_elasticache_subnet_group.discourse.id}"
  node_type = "${var.elasticache_instance_type}"
  num_cache_nodes = 1
  port = 11211

  security_group_ids = [
    "${aws_security_group.discourse_internal.id}"
  ]
}

# --
resource "aws_db_instance" "discourse" {
  storage_type = "gp2"
  username = "discourse"
  publicly_accessible = false
  db_subnet_group_name = "${aws_db_subnet_group.discourse.id}"
  instance_class = "${var.rds_instance_type}"
  availability_zone = "${var.zone-a}"
  password = "${var.db_password}"
  skip_final_snapshot = true
  engine_version  = "9.6.3"
  allocated_storage = 1024
  engine = "postgres"
  name = "discourse"
  multi_az = false

  # --
  # Enterprise Options
  # apply_immediately = false
  # backup_time = "01:00-3:00"
  # storage_encrypted = true
  # multi_az = true
  # --

  vpc_security_group_ids = [
    "${aws_security_group.discourse_internal.id}"
  ]
}

resource "aws_elb" "discourse-1" {
  name = "${var.slug}"
  cross_zone_load_balancing = true
  subnets = [ "${aws_subnet.discourse-a.id}", "${aws_subnet.discourse-b.id}" ]
  security_groups = [ "${aws_security_group.discourse_http.id}" ]
  instances = ["${aws_instance.discourse-1.id}"]
  connection_draining_timeout = 400
  connection_draining = true
  idle_timeout = 400

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_protocol = "http"
    lb_port = 80
  }

  health_check {
    healthy_threshold = 4
    unhealthy_threshold = 2
    target = "HTTP:80/"
    interval = 12
    timeout = 4
  }
}
