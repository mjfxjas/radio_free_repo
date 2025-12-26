terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "random_pet" "bucket_suffix" {
  length = 2
}

resource "random_password" "icecast_admin" {
  length  = 20
  special = false
  min_lower = 5
  min_upper = 5
  min_numeric = 5
}

resource "random_password" "icecast_source" {
  length  = 20
  special = false
  min_lower = 5
  min_upper = 5
  min_numeric = 5
}

resource "random_password" "icecast_relay" {
  length  = 20
  special = false
}

locals {
  icecast_admin_password  = var.icecast_admin_password != "" ? var.icecast_admin_password : random_password.icecast_admin.result
  icecast_source_password = var.icecast_source_password != "" ? var.icecast_source_password : random_password.icecast_source.result
  icecast_relay_password  = var.icecast_relay_password != "" ? var.icecast_relay_password : random_password.icecast_relay.result
  music_bucket_name       = var.music_bucket_name != "" ? var.music_bucket_name : lower("radio-free-music-${random_pet.bucket_suffix.id}")

  docker_compose_b64     = base64encode(file("${path.module}/../docker-compose.yml"))
  icecast_template_b64   = base64encode(file("${path.module}/../config/icecast.xml.template"))
  liquidsoap_template_b64 = base64encode(file("${path.module}/../config/radio.liq.template"))
  render_script_b64      = base64encode(file("${path.module}/../ops/bin/render-config.sh"))
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_s3_bucket" "music" {
  bucket        = local.music_bucket_name
  force_destroy = true
  tags          = var.tags

  lifecycle {
    create_before_destroy = false
    prevent_destroy       = false
  }
}

resource "aws_s3_bucket_public_access_block" "music" {
  bucket                  = aws_s3_bucket.music.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  depends_on = [aws_s3_bucket.music]
}

resource "aws_security_group" "radio" {
  name_prefix = "radio-free-"
  description = "Icecast/Liquidsoap access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Icecast"
    from_port   = var.icecast_port
    to_port     = var.icecast_port
    protocol    = "tcp"
    cidr_blocks = [var.icecast_ingress_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_iam_role" "instance" {
  name_prefix = "radio-free-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = { Service = "ec2.amazonaws.com" }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "s3_read" {
  name   = "radio-free-s3-read"
  role   = aws_iam_role.instance.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [aws_s3_bucket.music.arn, "${aws_s3_bucket.music.arn}/*"]
      }
    ]
  })
}

resource "aws_iam_instance_profile" "instance" {
  name_prefix = "radio-free-"
  role        = aws_iam_role.instance.name
}

resource "aws_instance" "radio" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.radio.id]
  iam_instance_profile   = aws_iam_instance_profile.instance.name
  associate_public_ip_address = false
  monitoring             = true

  user_data_base64 = base64encode(templatefile("${path.module}/templates/user_data.sh.tpl", {
    aws_region              = var.aws_region
    docker_compose_b64      = local.docker_compose_b64
    icecast_template_b64    = local.icecast_template_b64
    liquidsoap_template_b64 = local.liquidsoap_template_b64
    render_script_b64       = local.render_script_b64
    icecast_admin_password  = local.icecast_admin_password
    icecast_source_password = local.icecast_source_password
    icecast_relay_password  = local.icecast_relay_password
    icecast_port            = var.icecast_port
    icecast_mount           = var.icecast_mount
    station_name            = var.station_name
    station_description     = var.station_description
    stream_bitrate_kbps     = var.stream_bitrate_kbps
    music_bucket_name       = local.music_bucket_name
    music_prefix            = var.music_prefix
  }))

  user_data_replace_on_change = true

  root_block_device {
    volume_size           = var.root_volume_size_gb
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  lifecycle {
    ignore_changes = [ami]
  }

  tags = merge(var.tags, { Name = "radio-free" })
}
