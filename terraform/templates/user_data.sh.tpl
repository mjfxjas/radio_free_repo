#!/bin/bash
set -euo pipefail

exec > >(tee -a "/var/log/radio-user-data.log" | logger -t user-data -s 2>/dev/console) 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "AWS_DEFAULT_REGION=${aws_region}" >> /etc/environment
export AWS_DEFAULT_REGION=${aws_region}

if command -v dnf >/dev/null 2>&1; then
  dnf update -y
  dnf install -y docker awscli gettext
else
  yum update -y
  yum install -y docker awscli gettext
fi

# Docker Compose v2 binary
curl -sSL "https://github.com/docker/compose/releases/download/v2.24.6/docker-compose-linux-x86_64" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

systemctl enable docker
systemctl start docker

usermod -aG docker ec2-user || true

mkdir -p /opt/radio/config /opt/radio/ops/bin /opt/radio/ops/generated /opt/radio/ops/logs /var/radio/music
chown -R ec2-user:ec2-user /opt/radio /var/radio/music
mkdir -p /opt/radio/ops/logs/icecast /opt/radio/ops/logs/liquidsoap
chmod 777 /opt/radio/ops/logs/icecast /opt/radio/ops/logs/liquidsoap

# Drop project files
cat <<'EOF' | base64 -d > /opt/radio/docker-compose.yml
${docker_compose_b64}
EOF

cat <<'EOF' | base64 -d > /opt/radio/config/icecast.xml.template
${icecast_template_b64}
EOF

cat <<'EOF' | base64 -d > /opt/radio/config/radio.liq.template
${liquidsoap_template_b64}
EOF

cat <<'EOF' | base64 -d > /opt/radio/ops/bin/render-config.sh
${render_script_b64}
EOF
chmod +x /opt/radio/ops/bin/render-config.sh

# Environment for rendering configs
cat > /opt/radio/.env <<'EOF'
ICECAST_ADMIN_USERNAME=admin
ICECAST_ADMIN_PASSWORD="${icecast_admin_password}"
ICECAST_SOURCE_PASSWORD="${icecast_source_password}"
ICECAST_RELAY_PASSWORD="${icecast_relay_password}"
ICECAST_HOST=icecast
ICECAST_PORT=${icecast_port}
ICECAST_MOUNT="${icecast_mount}"
STREAM_BITRATE_KBPS=${stream_bitrate_kbps}
STATION_NAME="${station_name}"
STATION_DESCRIPTION="${station_description}"
MUSIC_ROOT=/var/radio/music
MUSIC_DIR=/radio/music
S3_MUSIC_BUCKET="${music_bucket_name}"
S3_MUSIC_PREFIX="${music_prefix}"
EOF

cd /opt/radio
sudo -u ec2-user /opt/radio/ops/bin/render-config.sh /opt/radio/.env

MUSIC_BUCKET="${music_bucket_name}"
MUSIC_PREFIX="${music_prefix}"
if [ -n "$MUSIC_BUCKET" ]; then
  aws s3 sync "s3://$MUSIC_BUCKET/$MUSIC_PREFIX" /var/radio/music || true
fi

# Start the stack
/usr/bin/docker-compose -f /opt/radio/docker-compose.yml pull
/usr/bin/docker-compose -f /opt/radio/docker-compose.yml up -d

cat <<'MSG'
==== radio_free_repo bootstrap complete ====
Check logs in /var/log/radio-user-data.log and container logs with docker ps/logs.
MSG
