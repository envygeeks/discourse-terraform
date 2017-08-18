resource "aws_instance" "discourse_1" {
  associate_public_ip_address = true
  instance_type = "${var.ec2_instance_type}"
  key_name = "${aws_key_pair.discourse_deploy.key_name}"
  subnet_id = "${aws_subnet.discourse_a.id}"
  availability_zone = "${var.zone_a}"
  ami = "${var.ec2_ami}"

  vpc_security_group_ids = [
    "${aws_security_group.discourse_ssh.id}",
    "${aws_security_group.discourse_internal_http.id}"
  ]

  tags {
    Name = "${var.slug}"
    Description = "${var.slug}"
    Stack = "${var.slug}"
  }

  root_block_device {
    volume_size = "12"
  }

  # --
  # We create a high timeout so that Discourse has time
  #   to setup, without us shutting it down.  Since these
  #   are going on the t2 tier, steal time can be a real
  #   problem when you first boot onto a cluster.
  # --
  timeouts {
    create = "30m"
  }

  # --
  # Do this early so that if there is a problem then you
  #   can SSH into the instance as everything is going wrong
  #   and figure it out while it's happening.
  # @example ssh ubuntu@$(cat ec2.txt)
  # --
  provisioner "local-exec" {
    command = "echo ${aws_instance.discourse_1.public_dns} > ec2.txt"
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
  provisioner "file" {
    content = "${data.template_file.docker.rendered}"
    destination = "~/daemon.json"
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
      <<-BASH
        sudo apt-get update && sudo apt-get dist-upgrade \
          -o Dpkg::Options::="--force-confdef" \
          -o Dpkg::Options::="--force-confold" \
          --assume-yes
      BASH
      ,

      <<-BASH
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88

        repo=https://download.docker.com/linux/ubuntu
        sudo add-apt-repository "deb [arch=amd64] $repo $(lsb_release -cs) stable"
        sudo apt-get update && sudo apt-get install docker-ce -y \
          --no-install-recommends
      BASH
      ,

      <<-BASH
        sudo mkdir -p /opt/discourse
        sudo chown ubuntu.ubuntu /opt/discourse
        git clone https://github.com/discourse/discourse_docker.git /opt/discourse
        mv ~/web.yml /opt/discourse/containers/web.yml
      BASH
      ,

      <<-BASH
        sudo mv ~/daemon.json /etc/docker/daemon.json
      BASH
      ,

      <<-BASH
        cd /opt/discourse
        sudo ./launcher bootstrap web
        sudo ./launcher start web
      BASH
    ]
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

  tags {
    Name = "${var.slug}"
    Description = "${var.slug}"
    Stack = "${var.slug}"
  }
}

# --
resource "aws_db_instance" "discourse" {
  storage_type = "gp2"
  username = "discourse"
  publicly_accessible = false
  db_subnet_group_name = "${aws_db_subnet_group.discourse.id}"
  instance_class = "${var.rds_instance_type}"
  availability_zone = "${var.zone_a}"
  password = "${var.db_password}"
  skip_final_snapshot = true
  engine_version  = "9.6.3"
  allocated_storage = 6
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

  tags {
    Name = "${var.slug}"
    Description = "${var.slug}"
    Stack = "${var.slug}"
  }
}

resource "aws_elb" "discourse_1" {
  name = "${var.slug}"
  cross_zone_load_balancing = true
  subnets = [ "${aws_subnet.discourse_a.id}", "${aws_subnet.discourse_b.id}" ]
  security_groups = [ "${aws_security_group.discourse_http.id}" ]
  instances = ["${aws_instance.discourse_1.id}"]
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

  tags {
    Name = "${var.slug}"
    Description = "${var.slug}"
    Stack = "${var.slug}"
  }

  provisioner "local-exec" {
    command = "echo ${aws_elb.discourse_1.dns_name} > elb.txt"
  }
}
