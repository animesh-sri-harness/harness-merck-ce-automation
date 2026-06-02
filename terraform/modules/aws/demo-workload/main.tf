locals {
  resource_suffix = var.legacy_resource_naming ? "ec2" : "${var.app_slug}-${var.env_key}"
  iam_suffix      = var.legacy_resource_naming ? "ec2" : var.app_slug
}

data "aws_ami" "chaos_demo" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "this" {
  name        = "${var.name_prefix}-demo-${local.resource_suffix}"
  description = var.legacy_resource_naming ? "Demo EC2 target for Harness AWS chaos faults" : "Demo EC2 chaos target for ${var.app_slug}/${var.env_key}"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${var.name_prefix}-demo-${local.resource_suffix}-sg" })
}

resource "aws_iam_role" "this" {
  name = "${var.name_prefix}-demo-${local.iam_suffix}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name_prefix}-demo-${local.iam_suffix}-profile"
  role = aws_iam_role.this.name
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.chaos_demo.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = merge(var.tags, {
    Name                                 = var.instance_name
    (var.platform.chaos_allowed_tag_key) = var.platform.chaos_allowed_tag_value
    "merck.harness.io/application"       = var.app_slug
    "merck.harness.io/environment"       = var.env_key
  })

  volume_tags = merge(var.tags, {
    (var.platform.chaos_allowed_tag_key) = var.platform.chaos_allowed_tag_value
  })
}
