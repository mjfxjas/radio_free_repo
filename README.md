# Radio Free Chattanooga

Icecast and Liquidsoap streaming setup with Docker, Terraform, and a static web player.

**Live Demo**: <https://www.theatrico.org/stream/>

## Overview

Liquidsoap selects MP3 audio and sends it to Icecast. Nginx proxies the stream, and the web player is served from S3 through CloudFront.

## Tech Stack

### Infrastructure

- **AWS EC2** - t3.micro instance running streaming server
- **AWS S3** - Static website hosting
- **AWS CloudFront** - CDN for global content delivery
- **AWS Route 53** - DNS management
- **Terraform** - Infrastructure as Code

### Streaming

- **Icecast 2.4.4** - Streaming media server
- **Liquidsoap 2.2.5** - Audio automation and playlist management
- **Docker & Docker Compose** - Container orchestration
- **nginx** - Reverse proxy with SSL termination
- **Let's Encrypt** - Free SSL certificates

### Frontend

- **Vanilla JavaScript** - No frameworks, pure ES6+
- **Responsive CSS** - Mobile-first design
- **Space Mono** - Monospace typography

## Architecture

### Data Flow

1. **Static Content**: Web player served via S3 → CloudFront → Client
2. **Audio Stream**: Liquidsoap → Icecast → nginx → Client
3. **Infrastructure**: Terraform provisions all AWS resources
4. **Deployment**: Docker Compose orchestrates streaming services on EC2

### Repository Structure

```
radio_free_repo/
├── terraform/          # AWS infrastructure provisioning
├── web/                 # Frontend web player (S3 hosted)
├── config/              # Icecast & Liquidsoap templates
├── ops/                 # Runtime configs, logs, scripts
├── music/               # Audio content library
└── docker-compose.yml   # Container orchestration
```

## Getting Started

### Prerequisites

- Docker & Docker Compose
- AWS CLI (for deployment)
- Terraform (for infrastructure)

### Local Development

1. **Clone and setup**

   ```bash
   git clone https://github.com/mjfxjas/radio_free_repo.git
   cd radio_free_repo
   cp .env.example .env
   ```

2. **Configure environment**

   ```bash
   # Edit .env with your passwords
   ICECAST_ADMIN_PASSWORD=your-admin-password
   ICECAST_SOURCE_PASSWORD=your-source-password
   ICECAST_RELAY_PASSWORD=your-relay-password
   ```

3. **Generate configs and start**

   ```bash
   ./ops/bin/render-config.sh
   docker-compose up -d
   ```

4. **Access locally**
   - Stream: <http://localhost:8000/stream>
   - Admin: <http://localhost:8000/admin>

## Deployment

### AWS Infrastructure

1. **Setup Terraform**

   ```bash
   cd terraform
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

2. **Deploy infrastructure**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. **Deploy web player**

   ```bash
   aws s3 sync web/ s3://your-bucket-name
   ```

## Configuration

### Environment Variables

- `ICECAST_ADMIN_PASSWORD` - Admin interface password
- `ICECAST_SOURCE_PASSWORD` - Source connection password
- `STATION_NAME` - Radio station name
- `STREAM_BITRATE_KBPS` - Audio quality (128 recommended)
- `MUSIC_ROOT` - Local music directory path

### Music Library

Place MP3 files in the `music/` directory. Liquidsoap will automatically shuffle and loop through all files.

## Usage

- **Listen**: Visit your CloudFront URL or local stream endpoint
- **Admin**: Access Icecast admin panel for monitoring
- **Logs**: Check `ops/logs/` for troubleshooting

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b fix/player-buffering`)
3. Commit changes (`git commit -m 'Handle player buffering'`)
4. Push to branch (`git push origin fix/player-buffering`)
5. Open Pull Request

## License

MIT License - see LICENSE file for details.
