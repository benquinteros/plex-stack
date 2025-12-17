# Plex Stack

A complete Docker Compose stack for automated media management with Plex, including VPN protection, monitoring, and content automation.

## 🎯 Overview

This repository provides a production-ready Docker Compose configuration for running a complete Plex media server ecosystem with automated content management, all secured behind a VPN.

### Included Services

| Service | Purpose | Web Port |
|---------|---------|----------|
| **Plex** | Media streaming server | 32400 |
| **Radarr** | Movie collection manager | 7878 |
| **Sonarr** | TV show collection manager | 8989 |
| **Prowlarr** | Indexer manager | 9696 |
| **Overseerr** | Media request platform | 5055 |
| **qBittorrent** | Torrent client (VPN protected) | 8080 |
| **FlareSolverr** | Cloudflare bypass proxy | 8191 |
| **Gluetun (PIA VPN)** | VPN container | 8000 |

## 📋 Prerequisites

- **Operating System**: Windows 10/11 with WSL2, Linux, or macOS
- **Docker**: Docker Engine 20.10+ and Docker Compose v2+
- **Storage**: Sufficient space for media files
- **VPN**: Private Internet Access (PIA) subscription
- **Plex**: Plex account (free or Plex Pass)

## 🚀 Quick Start

### 1. Run Setup Script (Windows)

```powershell
.\simple-setup.ps1
```

This will:
- Check for Docker installation
- Create required directory structure
- Generate a `.env` template file
- Provide next steps

### 2. Configure Environment Variables

Edit the `.env` file with your settings:

```bash
# Copy example file (if not using setup script)
cp .env.example .env

# Edit with your values
nano .env  # or use your preferred editor
```

**Required values:**
- `PUID` / `PGID`: Your user/group ID (run `id` in Linux/WSL)
- `TZ`: Your timezone (e.g., `America/New_York`)
- `BASE_PATH`: Docker config directory
- `MEDIA_SHARE`: Media storage location
- `PIA_USERNAME` / `PIA_PASSWORD`: Your PIA credentials
- `PLEX_CLAIM`: Claim token from [plex.tv/claim](https://www.plex.tv/claim)

### 3. Deploy the Stack

```bash
# Pull all images
docker-compose pull

# Start services in background
docker-compose up -d

# View logs
docker-compose logs -f
```

## 📁 Directory Structure

For optimal performance with hardlinks, organize your media storage as follows:

```
MEDIA_SHARE/
├── media/
│   ├── movies/         # Radarr output (mapped to Plex)
│   └── tv/             # Sonarr output (mapped to Plex)
└── downloads/
    ├── movies/         # Radarr category in qBittorrent
    ├── tv/             # Sonarr category in qBittorrent
    └── incomplete/     # Active downloads
```

**Important**: All services must use the same root path (`/share` in containers) for hardlinks to work.

See [TRaSH Guides](https://trash-guides.info/Hardlinks/Hardlinks-and-Instant-Moves/) for detailed explanation.

## ⚙️ Initial Configuration

### 1. qBittorrent
- URL: `http://localhost:8080`
- Default credentials: `admin` / check container logs for password
- **Action**: Change default password immediately
- **Configure Categories**:
  - Go to Settings → Downloads → Enable "Use Category paths"
  - Create category `movies` with path: `/share/downloads/movies`
  - Create category `tv` with path: `/share/downloads/tv`
  - Set "Default Save Path": `/share/downloads/incomplete`
- **Port Forwarding**: Forward port 8694 on your router for optimal seeding

### 2. Prowlarr
- URL: `http://localhost:9696`
- Add indexers (trackers/sources)
- Configure FlareSolverr: `http://flaresolverr:8191`
- Connect to Radarr and Sonarr

### 3. Radarr
- URL: `http://localhost:7878`
- Add qBittorrent as download client
- Set category: `movies`
- Configure media management with hardlinks

### 4. Sonarr
- URL: `http://localhost:8989`
- Add qBittorrent as download client
- Set category: `tv`
- Configure media management with hardlinks

### 5. Overseerr
- URL: `http://localhost:5055`
- Connect to Plex server
- Connect to Radarr and Sonarr

### 6. Plex
- URL: `http://localhost:32400/web`
- Add media libraries:
  - Movies: `/movies`
  - TV Shows: `/tv`

## 🔒 Security Considerations

- All torrent traffic routes through PIA VPN
- Change default passwords immediately
- Keep `.env` file secure (never commit to git)
- Regularly update container images
- Consider using a reverse proxy with SSL (Nginx Proxy Manager, Traefik)
- Enable authentication on all services

## 🔧 Maintenance

```bash
# Update all containers
docker-compose pull
docker-compose up -d

# View logs for specific service
docker-compose logs -f radarr

# Restart specific service
docker-compose restart plex

# Stop all services
docker-compose down

# Stop and remove volumes (WARNING: deletes config)
docker-compose down -v
```

## 🎛️ Advanced Configuration

### Hardware Transcoding (Intel QuickSync)

For Linux hosts with Intel 8th gen+ CPUs, uncomment in [docker-compose.yaml](docker-compose.yaml):

```yaml
devices:
  - /dev/dri:/dev/dri
```

### Reverse Proxy

For cleaner URLs (e.g., `radarr.yourdomain.com`):
1. Set up a reverse proxy (Nginx Proxy Manager, Traefik)
2. Configure SSL certificates
3. Update service proxy settings

### Resource Limits

Add resource constraints to prevent service hogging:

```yaml
deploy:
  resources:
    limits:
      cpus: '2'
      memory: 2G
```

## 🆘 Troubleshooting

| Issue | Solution |
|-------|----------|
| **VPN not connecting** | Check PIA credentials, verify region is valid |
| **Services can't reach internet** | Ensure VPN is running: `docker-compose logs pia-vpn` |
| **Permission denied errors** | Fix PUID/PGID in `.env`, check directory ownership |
| **Hardlinks not working** | Verify all paths use same root (`/share` in container) |
| **Port conflicts** | Check nothing else using ports, modify in compose file |

## 📚 Recommended Resources

- [TRaSH Guides](https://trash-guides.info/) - Quality profiles and optimization
- [Servarr Wiki](https://wiki.servarr.com/) - Official *arr documentation
- [r/Plex](https://reddit.com/r/Plex) - Community support
- [r/Sonarr](https://reddit.com/r/Sonarr) - Sonarr community
- [r/Radarr](https://reddit.com/r/Radarr) - Radarr community

## 🤝 Contributing

Contributions welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## ⚖️ License

This project is for educational purposes. Ensure you comply with:
- Local copyright laws
- Terms of service for all included software
- VPN provider terms
- Content provider terms

## 🙏 Acknowledgments

- LinuxServer.io for excellent container images
- TRaSH Guides for optimization guidance
- The *arr development teams
- Plex for their media server platform

