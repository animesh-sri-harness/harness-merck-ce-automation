# Demo EC2 target for AWS chaos faults (tagged Chaos=allowed per Merck TSA).

data "aws_ami" "chaos_demo" {
  count = var.create_chaos_demo_ec2 ? 1 : 0

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

resource "aws_security_group" "chaos_demo_ec2" {
  count = var.create_chaos_demo_ec2 ? 1 : 0

  name        = "${var.name_prefix}-demo-ec2"
  description = "Demo EC2 target for Harness AWS chaos faults"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-demo-ec2-sg"
  })
}

resource "aws_iam_role" "chaos_demo_ec2" {
  count = var.create_chaos_demo_ec2 ? 1 : 0

  name = "${var.name_prefix}-demo-ec2-role"

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

resource "aws_iam_role_policy_attachment" "chaos_demo_ec2_ssm" {
  count = var.create_chaos_demo_ec2 ? 1 : 0

  role       = aws_iam_role.chaos_demo_ec2[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "chaos_demo_ec2" {
  count = var.create_chaos_demo_ec2 ? 1 : 0

  name = "${var.name_prefix}-demo-ec2-profile"
  role = aws_iam_role.chaos_demo_ec2[0].name
}

resource "aws_instance" "chaos_demo" {
  count = var.create_chaos_demo_ec2 ? 1 : 0

  ami                         = data.aws_ami.chaos_demo[0].id
  instance_type               = var.chaos_demo_instance_type
  subnet_id                   = module.vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.chaos_demo_ec2[0].id]
  iam_instance_profile        = aws_iam_instance_profile.chaos_demo_ec2[0].name
  associate_public_ip_address = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "Merck chaos demo EC2 ready" > /var/log/merck-chaos-demo.ready
    EOF

  tags = merge(var.tags, {
    Name                           = var.chaos_demo_instance_name
    (var.chaos_allowed_tag_key)    = var.chaos_allowed_tag_value
    "merck.harness.io/environment" = var.chaos_demo_environment
    "merck.harness.io/application" = var.application_slug
  })

  volume_tags = merge(var.tags, {
    (var.chaos_allowed_tag_key) = var.chaos_allowed_tag_value
  })

  depends_on = [module.vpc]
}
