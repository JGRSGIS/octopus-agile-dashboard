# Deployment Guide

This guide covers deploying the Octopus Agile Dashboard to production environments.

## Deployment Options

1. **Raspberry Pi** - Recommended for home use
2. **Docker** - For containerized deployments
3. **Cloud VPS** - For remote access

---

## Prerequisites

Before deploying, ensure you have:

- [x] Octopus Energy account with API key
- [x] MPAN and meter serial number
- [x] PostgreSQL 14+ installed and running
- [x] Node.js 18+ (for building frontend)
- [x] Python 3.11+

---

## Raspberry Pi Deployment

### Automated Setup

The easiest way to deploy on a Raspberry Pi:

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/octopus-agile-dashboard.git
cd octopus-agile-dashboard

# Run the automated setup script
./scripts/setup_raspberry_pi.sh
```

The script will:
1. Update the system
2. Install all dependencies (Python, Node.js, PostgreSQL, Nginx)
3. Create the database
4. Set up the backend as a systemd service
5. Build and deploy the frontend
6. Configure Nginx as a reverse proxy
7. Set up cron jobs for data fetching

### Manual Setup

See the main README.md for step-by-step manual installation instructions.

---

## Docker Deployment

### Using Docker Compose

```bash
# Copy and configure environment
cp .env.example .env
nano .env  # Add your credentials

# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### Services

The `docker-compose.yml` includes:
- **backend**: FastAPI application (port 8000)
- **frontend**: Nginx serving React build (port 80)
- **postgres**: PostgreSQL database (port 5432)

### Environment Variables for Docker

```bash
# .env file for Docker
POSTGRES_USER=octopus
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=octopus_agile

# Application settings
OCTOPUS_API_KEY=sk_live_xxxxx
MPAN=2000000000000
SERIAL_NUMBER=00A0000000
REGION=H
```

---

## Cloud VPS Deployment

### Ubuntu/Debian Server

1. **Initial Setup**
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y python3-pip python3-venv nodejs npm postgresql postgresql-contrib nginx certbot python3-certbot-nginx

# Create application user
sudo useradd -m -s /bin/bash octopus
sudo su - octopus
```

2. **Clone and Configure**
```bash
git clone https://github.com/YOUR_USERNAME/octopus-agile-dashboard.git
cd octopus-agile-dashboard
cp .env.example .env
nano .env
```

3. **Database Setup**
```bash
sudo -u postgres createuser octopus
sudo -u postgres createdb -O octopus octopus_agile
```

4. **SSL with Let's Encrypt**
```bash
sudo certbot --nginx -d yourdomain.com
```

---

## Production Configuration

### Environment Variables

| Variable | Production Value | Description |
|----------|------------------|-------------|
| DEBUG | false | Disable debug mode |
| DATABASE_URL | postgresql+asyncpg://... | Production database |
| CORS_ORIGINS | ["https://yourdomain.com"] | Allowed origins |

### Security Checklist

- [ ] Change default database password
- [ ] Set DEBUG=false
- [ ] Configure firewall (UFW)
- [ ] Enable SSL/HTTPS
- [ ] Restrict CORS origins
- [ ] Keep API key secure (never commit to git)

### Firewall Configuration

```bash
# Allow SSH, HTTP, HTTPS
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw enable
```

---

## Maintenance

### Updating the Application

```bash
cd ~/octopus-agile-dashboard
git pull origin main

# Update backend
cd backend
source venv/bin/activate
pip install -r requirements.txt
sudo systemctl restart octopus-backend

# Update frontend
cd ../frontend
npm install
npm run build
```

### Database Backups

```bash
# Backup database
pg_dump -U octopus octopus_agile > backup_$(date +%Y%m%d).sql

# Restore database
psql -U octopus octopus_agile < backup_20240101.sql
```

### Log Management

```bash
# View backend logs
sudo journalctl -u octopus-backend -f

# View nginx logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# View cron job logs
tail -f ~/logs/fetch.log
```

### Data Cleanup

The `cleanup_old_data.sh` script runs daily to remove data older than 90 days:

```bash
# Manual cleanup
./scripts/cleanup_old_data.sh

# Change retention period (default 90 days)
RETENTION_DAYS=60 ./scripts/cleanup_old_data.sh
```

---

## Monitoring

### Health Check Endpoint

```bash
curl http://localhost:8000/api/health
```

### Systemd Service Status

```bash
sudo systemctl status octopus-backend
sudo systemctl status nginx
sudo systemctl status postgresql
```

---

## Troubleshooting

### Backend Won't Start

1. Check PostgreSQL is running: `sudo systemctl status postgresql`
2. Verify database exists: `sudo -u postgres psql -l | grep octopus`
3. Check environment file: `cat .env`
4. View error logs: `sudo journalctl -u octopus-backend -n 50`

### Frontend Build Fails

1. Check Node.js version: `node --version` (need 18+)
2. Clear npm cache: `npm cache clean --force`
3. Delete node_modules: `rm -rf node_modules && npm install`

### Database Connection Issues

1. Check connection string format in `.env`
2. Verify user permissions: `sudo -u postgres psql -c "\du"`
3. Test connection: `psql -h localhost -U octopus -d octopus_agile`

### No Data Showing

1. Check cron jobs are running: `crontab -l`
2. Manually run fetch script: `./scripts/fetch_prices.sh`
3. Check API key is valid in Octopus dashboard
