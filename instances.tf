data "aws_ami" "ubuntu" {

  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Script to install Consul
data "template_file" "script" {
  template = file("${path.module}/templates/userdata.sh")
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = false
  part {
    content_type = "text/x-shellscript"
    content      = data.template_file.script.rendered
  }
}

resource "null_resource" "consul_create_certs" {
  triggers = {
    instance_ids = timestamp()
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      mkdir certs
      cd certs
      curl -s https://releases.hashicorp.com/consul/1.9.6/consul_1.9.6_linux_amd64.zip -o consul.zip
      unzip consul.zip
      ./consul tls ca create
      ./consul tls cert create -server -dc dc1
      ./consul tls cert create -client -dc dc1
    EOT
  }
}

resource "null_resource" "consul_push_certs" {
  count = var.instance_count

  triggers = {
    instance_ids = element(flatten(module.consul_instance[*].public_dns), count.index)
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = var.ssh_private_key
    host        = element(flatten(module.consul_instance[*].public_dns), count.index)
  }


  provisioner "file" {
    source      = "certs"
    destination = "/tmp/certs"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkdir -p /etc/consul.d/certs || true",
      "sudo mv /tmp/certs/* /etc/consul.d/certs/ ",
      "sudo chown -R consul:consul /etc/consul.d || true"
    ]
  }
}

# Instance configuration
module "consul_instance" {
  count                       = var.instance_count
  source                      = "github.com/flamarion/terraform-aws-ec2?ref=v0.0.9"
  ami                         = data.aws_ami.ubuntu.id
  subnet_id                   = data.terraform_remote_state.vpc.outputs.public_subnets_id[count.index]
  instance_type               = "t2.medium"
  key_name                    = aws_key_pair.tfe_key.key_name
  user_data                   = data.template_cloudinit_config.config.rendered
  vpc_security_group_ids      = [module.instance_sg.sg_id]
  associate_public_ip_address = true
  root_volume_size            = 100
  iam_instance_profile        = aws_iam_instance_profile.consul_instance_profile.name
  ec2_tags = {
    Name = "${var.owner}-consul-${count.index}-instance"
    Role = "Consul_Server"
  }
}


# IAM Role, Policy and Instance Profile 
resource "aws_iam_role" "consul_retry_join_role" {
  name               = "${var.owner}-consul-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
     {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "consul_instance_profile" {
  name = "${var.owner}-consul-profile"
  role = aws_iam_role.consul_retry_join_role.name
}

resource "aws_iam_policy" "consul_retry_join_policy" {
  name   = "${var.owner}-consul-policy"
  path   = "/"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy_attach" {
  role       = aws_iam_role.consul_retry_join_role.name
  policy_arn = aws_iam_policy.consul_retry_join_policy.arn
}
