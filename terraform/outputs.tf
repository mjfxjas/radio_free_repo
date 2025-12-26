output "icecast_stream_url" {
  value       = "http://${aws_instance.radio.public_ip}:${var.icecast_port}${var.icecast_mount}"
  description = "Public URL for the stream"
}

output "icecast_admin_password" {
  value       = local.icecast_admin_password
  description = "Icecast admin password"
  sensitive   = true
}

output "icecast_source_password" {
  value       = local.icecast_source_password
  description = "Icecast source password"
  sensitive   = true
}

output "icecast_relay_password" {
  value       = local.icecast_relay_password
  description = "Icecast relay password"
  sensitive   = true
}

output "music_bucket_name" {
  value       = aws_s3_bucket.music.bucket
  description = "S3 bucket holding music files"
}

output "instance_public_ip" {
  value       = aws_instance.radio.public_ip
  description = "Public IP for the EC2 instance"
}
