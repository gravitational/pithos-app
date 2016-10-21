provider "aws" {
  region = "us-east-1"
}

variable "ssh_key" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "app_node" {
  default = 3
}

variable "load_node" {
  default = 1
}

output "app_node_public_ips" {
  value = "${join(" ", aws_instance.app_node.*.public_ip)}"
}

output "app_node_private_ips" {
  value = "${join(" ", aws_instance.app_node.*.private_ip)}"
}

output "app_node_public_dns" {
  value = "${join(" ", aws_instance.app_node.*.public_dns)}"
}

output "app_node_private_dns" {
  value = "${join(" ", aws_instance.app_node.*.private_dns)}"
}

output "load_node_public_ips" {
  value = "${join(" ", aws_instance.load_node.*.public_ip)}"
}

output "load_node_private_ips" {
  value = "${join(" ", aws_instance.load_node.*.private_ip)}"
}

output "load_node_public_dns" {
  value = "${join(" ", aws_instance.load_node.*.public_dns)}"
}

output "load_node_private_dns" {
  value = "${join(" ", aws_instance.load_node.*.private_dns)}"
}

resource "aws_placement_group" "cluster" {
  name     = "${var.cluster_name}"
  strategy = "cluster"
}

# ALL UDP and TCP traffic is allowed within the security group
resource "aws_security_group" "cluster" {
  tags {
    Name = "${var.cluster_name}"
  }

  # Admin gravity site for testing
  ingress {
    from_port   = 32009
    to_port     = 32009
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # install wizard
  ingress {
    from_port   = 61009
    to_port     = 61009
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app_node" {
  # CentOS 7 (Enhanced Networking / lvm2)
  ami = "ami-366be821"

  # This instance type has two ephemeral devices
  instance_type               = "c3.2xlarge"
  associate_public_ip_address = true
  source_dest_check           = "false"
  ebs_optimized               = true
  security_groups             = ["${aws_security_group.cluster.name}"]
  key_name                    = "${var.ssh_key}"
  placement_group             = "${aws_placement_group.cluster.id}"
  count                       = "${var.app_node}"

  tags {
    Name = "${var.cluster_name}"
    Type = "application"
  }

  # Logs in /var/lib/cloud-init-output.log
  user_data = <<EOF
#!/bin/bash

set -xe

umount /dev/xvdb
umount /dev/xvdc

mkfs.ext4 /dev/xvdb
mkfs.ext4 /dev/xvdc
mkfs.ext4 /dev/xvdf

sed -i.bak '/xvdb/d' /etc/fstab
sed -i.bak '/xvdc/d' /etc/fstab
echo -e '/dev/xvdb\t/var/lib/gravity\text4\tdefaults\t0\t2' >> /etc/fstab
echo -e '/dev/xvdc\t/var/lib/data\text4\tdefaults\t0\t2' >> /etc/fstab
echo -e '/dev/xvdf\t/var/lib/gravity/planet/etcd\text4\tdefaults\t0\t2' >> /etc/fstab

mkdir -p /var/lib/gravity /var/lib/data
mount /var/lib/gravity
mount /var/lib/data
mkdir -p /var/lib/gravity/planet/etcd
mount /var/lib/gravity/planet/etcd
chown -R 1000:1000 /var/lib/gravity /var/lib/data /var/lib/gravity/planet/etcd
sed -i.bak 's/Defaults    requiretty/#Defaults    requiretty/g' /etc/sudoers
EOF

  root_block_device {
    delete_on_termination = true
    volume_type           = "io1"
    volume_size           = "50"
    iops                  = 500
  }

  # /var/lib/gravity device
  ephemeral_block_device = {
    virtual_name = "ephemeral0"
    device_name  = "/dev/xvdb"
  }

  # /var/lib/data device
  ephemeral_block_device = {
    virtual_name = "ephemeral1"
    device_name  = "/dev/xvdc"
  }

  # gravity/docker data device
  ebs_block_device = {
    volume_size           = "100"
    volume_type           = "io1"
    device_name           = "/dev/xvde"
    iops                  = 3000
    delete_on_termination = true
  }

  # etcd device
  ebs_block_device = {
    volume_size           = "100"
    volume_type           = "io1"
    device_name           = "/dev/xvdf"
    iops                  = 3000
    delete_on_termination = true
  }
}

resource "aws_instance" "load_node" {
  # CentOS 7 (Enhanced Networking / lvm2)
  ami = "ami-366be821"

  # Need for the same placement_group
  instance_type               = "c3.2xlarge"
  associate_public_ip_address = true
  source_dest_check           = "false"
  ebs_optimized               = true
  security_groups             = ["${aws_security_group.cluster.name}"]
  key_name                    = "${var.ssh_key}"
  placement_group             = "${aws_placement_group.cluster.id}"
  count                       = "${var.load_node}"

  tags {
    Name = "${var.cluster_name}"
    Type = "load-generator"
  }

  # Logs in /var/lib/cloud-init-output.log
  user_data = <<EOF
#!/bin/bash

set -xe

yum install -y python openssl-devel git
easy_install awscli
git clone https://github.com/giltene/wrk2 /tmp/wrk2
cd /tmp/wrk2 && make && mv wrk /usr/local/bin/wrk2 && cd - && rm -rf /tmp/wrk2
echo 'pathmunge /usr/local/bin' >> /etc/profile.d/add-usr-local-bin.sh
EOF
}
