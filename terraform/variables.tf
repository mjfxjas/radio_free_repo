variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "The aws_region must be a valid AWS region format (e.g., us-east-1)."
  }
}

variable "instance_type" {
  description = "Instance type for the EC2 host"
  type        = string
  default     = "t3.micro"

  validation {
    condition     = can(regex("^[a-z][0-9][a-z]?\\.(nano|micro|small|medium|large|xlarge|[0-9]+xlarge)$", var.instance_type))
    error_message = "The instance_type must be a valid EC2 instance type (e.g., t3.micro)."
  }
}

variable "root_volume_size_gb" {
  description = "Root volume size for the instance (stores music + containers)"
  type        = number
  default     = 40
}

variable "icecast_port" {
  description = "Host port to expose Icecast on"
  type        = number
  default     = 8000

  validation {
    condition     = var.icecast_port > 0 && var.icecast_port <= 65535
    error_message = "The icecast_port must be between 1 and 65535."
  }
}

variable "icecast_mount" {
  description = "Mount path for the stream (must start with /)"
  type        = string
  default     = "/stream"

  validation {
    condition     = can(regex("^/", var.icecast_mount))
    error_message = "The icecast_mount must start with /."
  }
}

variable "icecast_ingress_cidr" {
  description = "CIDR block allowed to reach Icecast"
  type        = string
  default     = "0.0.0.0/0"

  validation {
    condition     = can(cidrhost(var.icecast_ingress_cidr, 0))
    error_message = "The icecast_ingress_cidr must be a valid CIDR block."
  }
}

variable "icecast_admin_password" {
  description = "Optional override for the Icecast admin password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "icecast_source_password" {
  description = "Optional override for the Icecast source password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "icecast_relay_password" {
  description = "Optional override for the Icecast relay password"
  type        = string
  default     = ""
  sensitive   = true
}

variable "stream_bitrate_kbps" {
  description = "MP3 bitrate sent from Liquidsoap to Icecast"
  type        = number
  default     = 128
}

variable "station_name" {
  description = "Stream name shown to listeners"
  type        = string
  default     = "Radio Free"
}

variable "station_description" {
  description = "Stream description shown to listeners"
  type        = string
  default     = "Liquidsoap -> Icecast demo stream"
}

variable "music_bucket_name" {
  description = "Optional: provide your own S3 bucket name; leave blank to create a random one"
  type        = string
  default     = ""

  validation {
    condition     = var.music_bucket_name == "" || can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.music_bucket_name))
    error_message = "The music_bucket_name must be a valid S3 bucket name (3-63 chars, lowercase, numbers, hyphens, dots)."
  }
}

variable "music_prefix" {
  description = "Prefix (folder) inside the bucket that holds audio files"
  type        = string
  default     = "library/"

  validation {
    condition     = can(regex("^[a-zA-Z0-9/_-]*$", var.music_prefix))
    error_message = "The music_prefix must contain only alphanumeric characters, slashes, hyphens, and underscores."
  }
}

variable "tags" {
  description = "Tags applied to AWS resources"
  type        = map(string)
  default = {
    Project = "radio-free"
  }
}
