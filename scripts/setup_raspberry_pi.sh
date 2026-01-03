#!/bin/bash
# ============================================
# Raspberry Pi Automated Setup Script
# Octopus Agile Dashboard
# ============================================

set -e

echo "================================================"
echo "Octopus Agile Dashboard - Raspberry Pi Setup"
echo "================================================"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo -e "${RED}Please run as normal user, not root${NC}"
    exit 1
fi

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "Project directory: $PROJECT_DIR"
echo ""

# ============================================
# Step 1: System Update
# ============================================
echo -e "${YELLOW}Step 1: Updating system...${NC}"
sudo apt update && sudo apt upgrade -y

# ============================================
# Step 2: Install Dependencies
# ============================================
echo -e "${YELLOW}Step 2: Installing dependencies...${NC}"

# Fix any broken packages first
sudo apt --fix-broken install -y || true

# Check if nginx is in a broken state and fix it
if dpkg -l nginx 2>/dev/null | grep -q '^iF'; then
    echo -e "${YELLOW}Detected broken nginx installation, fixing...${NC}"
    sudo apt purge -y nginx nginx-common nginx-core 2>/dev/null || true
    sudo apt autoremove -y
fi

# Install dependencies (excluding nginx initially)
sudo apt install -y \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    postgresql \
    postgresql-contrib \
    git \
    curl

# Install nginx separately with error handling
echo "Installing nginx..."
if ! sudo apt install -y nginx; then
    echo -e "${YELLOW}Nginx installation failed, attempting recovery...${NC}"
    # Purge any partial nginx installation
    sudo apt purge -y nginx nginx-common nginx-core 2>/dev/null || true
    sudo rm -rf /etc/nginx 2>/dev/null || true
    sudo apt autoremove -y
    sudo apt update
    # Try installing again
    if ! sudo apt install -y nginx; then
        echo -e "${RED}Failed to install nginx. Please run manually:${NC}"
        echo "  sudo apt purge nginx nginx-common"
        echo "  sudo apt install nginx"
        exit 1
    fi
fi

# Verify nginx configuration exists
if [ ! -f /etc/nginx/nginx.conf ]; then
    echo -e "${RED}Error: nginx.conf not found after installation${NC}"
    echo "Attempting to reinstall nginx-common..."
    sudo apt install --reinstall -y nginx-common nginx-core
fi

echo -e "${GREEN}All dependencies installed${NC}"

# ============================================
# Step 3: Setup PostgreSQL
# ============================================
echo -e "${YELLOW}Step 3: Setting up PostgreSQL...${NC}"

# Get PostgreSQL version
PG_VERSION=$(ls /usr/lib/postgresql/ 2>/dev/null | sort -V | tail -n1)
if [ -z "$PG_VERSION" ]; then
    echo -e "${RED}PostgreSQL installation not found${NC}"
    exit 1
fi
echo "PostgreSQL version: $PG_VERSION"

# Check if the main cluster exists and is initialized
PG_CLUSTER_DIR="/var/lib/postgresql/$PG_VERSION/main"
if [ ! -d "$PG_CLUSTER_DIR" ] || [ ! -f "$PG_CLUSTER_DIR/PG_VERSION" ]; then
    echo -e "${YELLOW}PostgreSQL cluster not initialized, creating...${NC}"
    # Stop any running postgresql service first
    sudo systemctl stop postgresql 2>/dev/null || true
    # Create the cluster
    sudo pg_dropcluster --stop $PG_VERSION main 2>/dev/null || true
    sudo pg_createcluster $PG_VERSION main --start
    echo -e "${GREEN}PostgreSQL cluster created${NC}"
else
    echo "PostgreSQL cluster exists at $PG_CLUSTER_DIR"
fi

# Ensure PostgreSQL service is stopped before starting fresh
sudo systemctl stop postgresql 2>/dev/null || true
sleep 1

# Start PostgreSQL
echo "Starting PostgreSQL service..."
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to be ready..."
MAX_ATTEMPTS=60
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    # Check if the service is actually running
    if ! systemctl is-active --quiet postgresql; then
        if [ $ATTEMPT -eq 0 ]; then
            # First attempt - service might still be starting
            sleep 1
            ATTEMPT=$((ATTEMPT + 1))
            continue
        fi
        echo -e "${RED}PostgreSQL service is not running${NC}"
        echo "Attempting to diagnose the issue..."
        sudo systemctl status postgresql --no-pager || true
        echo ""
        echo "Checking PostgreSQL logs:"
        sudo journalctl -xeu postgresql@$PG_VERSION-main.service --no-pager -n 20 || true
        exit 1
    fi

    # Service is running, check if it's accepting connections
    if sudo -u postgres pg_isready -q 2>/dev/null; then
        echo -e "${GREEN}PostgreSQL is ready${NC}"
        break
    fi

    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
        echo -e "${RED}PostgreSQL failed to accept connections within 60 seconds${NC}"
        echo "Service status:"
        sudo systemctl status postgresql --no-pager || true
        echo ""
        echo "Check logs with: sudo journalctl -xeu postgresql@$PG_VERSION-main.service"
        exit 1
    fi
    sleep 1
done

# Create database and user (will prompt for password)
echo "Creating database..."
read -sp "Enter password for database user 'octopus': " DB_PASSWORD
echo ""

sudo -u postgres psql -c "CREATE USER octopus WITH PASSWORD '$DB_PASSWORD';" 2>/dev/null || true
sudo -u postgres psql -c "CREATE DATABASE octopus_agile OWNER octopus;" 2>/dev/null || true
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE octopus_agile TO octopus;"
# PostgreSQL 15+ requires explicit schema permissions
sudo -u postgres psql -d octopus_agile -c "GRANT ALL ON SCHEMA public TO octopus;"

echo -e "${GREEN}Database created successfully${NC}"

# ============================================
# Step 4: Setup Environment
# ============================================
echo -e "${YELLOW}Step 4: Setting up environment...${NC}"

if [ ! -f "$PROJECT_DIR/.env" ]; then
    cp "$PROJECT_DIR/.env.example" "$PROJECT_DIR/.env"
    
    # Update database URL
    sed -i "s/your_password/$DB_PASSWORD/g" "$PROJECT_DIR/.env"
    
    echo -e "${YELLOW}Please edit .env file with your Octopus Energy credentials:${NC}"
    echo "  nano $PROJECT_DIR/.env"
    echo ""
    read -p "Press Enter after editing .env file..."
fi

# ============================================
# Step 5: Setup Backend
# ============================================
echo -e "${YELLOW}Step 5: Setting up backend...${NC}"

cd "$PROJECT_DIR/backend"

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install --upgrade pip
pip install -r requirements.txt

# Run database migrations
echo "Running database migrations..."
alembic upgrade head

echo -e "${GREEN}Backend setup complete${NC}"

# ============================================
# Step 6: Setup Frontend
# ============================================
echo -e "${YELLOW}Step 6: Setting up frontend...${NC}"

cd "$PROJECT_DIR/frontend"

# Check available memory and swap
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
SWAP_SIZE=$(free -m | awk '/^Swap:/{print $2}')

echo "Available RAM: ${TOTAL_MEM}MB, Swap: ${SWAP_SIZE}MB"

# If low memory and no swap, create temporary swap
if [ "$TOTAL_MEM" -lt 2048 ] && [ "$SWAP_SIZE" -lt 1024 ]; then
    echo -e "${YELLOW}Low memory detected. Creating temporary swap file...${NC}"
    if [ ! -f /swapfile ]; then
        sudo fallocate -l 2G /swapfile 2>/dev/null || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo -e "${GREEN}Swap file created and enabled${NC}"
    else
        sudo swapon /swapfile 2>/dev/null || true
        echo "Existing swap file enabled"
    fi
    # Wait for swap to be fully available before memory-intensive operations
    sleep 2
    sync
fi

# Install dependencies
npm install

# Build with memory settings appropriate for available memory + swap
# With 2GB swap file, we can safely use 1024MB heap (leaves room for OS and other processes)
echo "Building frontend with memory-optimized settings..."
export NODE_OPTIONS="--max-old-space-size=1024"
npm run build

echo -e "${GREEN}Frontend build complete${NC}"

# ============================================
# Step 7: Setup Systemd Service
# ============================================
echo -e "${YELLOW}Step 7: Setting up systemd service...${NC}"

# Create service file
sudo tee /etc/systemd/system/octopus-backend.service > /dev/null << EOF
[Unit]
Description=Octopus Agile Dashboard Backend
After=network.target postgresql.service

[Service]
User=$USER
Group=$USER
WorkingDirectory=$PROJECT_DIR/backend
Environment="PATH=$PROJECT_DIR/backend/venv/bin"
EnvironmentFile=$PROJECT_DIR/.env
ExecStart=$PROJECT_DIR/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload and enable service
sudo systemctl daemon-reload
sudo systemctl enable octopus-backend
sudo systemctl start octopus-backend

echo -e "${GREEN}Backend service created and started${NC}"

# ============================================
# Step 8: Setup Nginx
# ============================================
echo -e "${YELLOW}Step 8: Setting up Nginx...${NC}"

sudo tee /etc/nginx/sites-available/octopus-agile > /dev/null << EOF
server {
    listen 0.0.0.0:80;
    listen [::]:80;
    server_name raspberrypi.local _;

    location / {
        root $PROJECT_DIR/frontend/dist;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF

# Enable site
sudo ln -sf /etc/nginx/sites-available/octopus-agile /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test and restart nginx
if ! sudo nginx -t; then
    echo -e "${RED}Nginx configuration test failed${NC}"
    echo "Please check the configuration manually"
    exit 1
fi

sudo systemctl restart nginx
sudo systemctl enable nginx

# Verify nginx is running
if ! systemctl is-active --quiet nginx; then
    echo -e "${RED}Warning: Nginx failed to start${NC}"
    echo "Check status with: sudo systemctl status nginx"
    echo "Check logs with: sudo journalctl -xeu nginx.service"
else
    echo -e "${GREEN}Nginx configured and running${NC}"
fi

# ============================================
# Step 9: Setup Cron Jobs
# ============================================
echo -e "${YELLOW}Step 9: Setting up cron jobs...${NC}"

# Create log directory
mkdir -p ~/logs

# Make scripts executable
chmod +x "$PROJECT_DIR/scripts/"*.sh

# Add cron jobs
(crontab -l 2>/dev/null || true; echo "*/30 * * * * $PROJECT_DIR/scripts/fetch_prices.sh >> ~/logs/fetch.log 2>&1") | sort -u | crontab -
(crontab -l 2>/dev/null || true; echo "0 * * * * $PROJECT_DIR/scripts/fetch_consumption.sh >> ~/logs/consumption.log 2>&1") | sort -u | crontab -
(crontab -l 2>/dev/null || true; echo "0 3 * * * $PROJECT_DIR/scripts/cleanup_old_data.sh >> ~/logs/cleanup.log 2>&1") | sort -u | crontab -

echo -e "${GREEN}Cron jobs configured${NC}"

# ============================================
# Step 10: Initial Data Fetch
# ============================================
echo -e "${YELLOW}Step 10: Fetching initial data...${NC}"

source "$PROJECT_DIR/backend/venv/bin/activate"
"$PROJECT_DIR/scripts/fetch_prices.sh" || true

# ============================================
# Complete!
# ============================================
echo ""
echo "================================================"
echo -e "${GREEN}Setup Complete!${NC}"
echo "================================================"
echo ""
echo "Dashboard URL: http://raspberrypi.local"
echo "              or http://$(hostname -I | awk '{print $1}')"
echo ""
echo "Useful commands:"
echo "  sudo systemctl status octopus-backend  # Check backend status"
echo "  sudo journalctl -u octopus-backend -f  # View backend logs"
echo "  tail -f ~/logs/fetch.log               # View fetch logs"
echo ""
echo "To access from outside your network, consider:"
echo "  - Setting up Tailscale VPN"
echo "  - Configuring port forwarding on your router"
echo ""
