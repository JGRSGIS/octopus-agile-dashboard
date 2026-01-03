#!/bin/bash
# ============================================
# Purge Script - Complete Uninstall
# Octopus Agile Dashboard
# ============================================
# This script removes everything installed by setup_raspberry_pi.sh
# Use this when relocating to another device or starting fresh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo ""
echo "================================================"
echo -e "${RED}Octopus Agile Dashboard - PURGE SCRIPT${NC}"
echo "================================================"
echo ""
echo -e "${YELLOW}WARNING: This script will remove:${NC}"
echo "  - Systemd service (octopus-backend)"
echo "  - Nginx configuration"
echo "  - PostgreSQL database and user"
echo "  - Cron jobs for price/consumption fetching"
echo "  - Python virtual environment"
echo "  - Frontend build files and node_modules"
echo "  - Log files"
echo "  - Docker containers and volumes (if applicable)"
echo "  - Environment file (.env)"
echo ""
echo -e "${BLUE}Project directory: $PROJECT_DIR${NC}"
echo ""

# ============================================
# Confirmation
# ============================================
read -p "Are you sure you want to continue? (type 'yes' to confirm): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${YELLOW}Purge cancelled.${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Starting purge...${NC}"
echo ""

# Track what was removed
REMOVED_ITEMS=()

# ============================================
# Step 1: Stop and Remove Systemd Service
# ============================================
echo -e "${YELLOW}Step 1: Removing systemd service...${NC}"

if systemctl list-unit-files | grep -q octopus-backend.service; then
    sudo systemctl stop octopus-backend 2>/dev/null || true
    sudo systemctl disable octopus-backend 2>/dev/null || true
    sudo rm -f /etc/systemd/system/octopus-backend.service
    sudo systemctl daemon-reload
    REMOVED_ITEMS+=("Systemd service")
    echo -e "${GREEN}  Removed octopus-backend service${NC}"
else
    echo "  Service not found, skipping..."
fi

# ============================================
# Step 2: Remove Nginx Configuration
# ============================================
echo -e "${YELLOW}Step 2: Removing Nginx configuration...${NC}"

if [ -f /etc/nginx/sites-available/octopus-agile ]; then
    sudo rm -f /etc/nginx/sites-enabled/octopus-agile
    sudo rm -f /etc/nginx/sites-available/octopus-agile

    # Restore default site if nginx is installed
    if [ -f /etc/nginx/sites-available/default ]; then
        sudo ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default 2>/dev/null || true
    fi

    sudo nginx -t 2>/dev/null && sudo systemctl reload nginx 2>/dev/null || true
    REMOVED_ITEMS+=("Nginx configuration")
    echo -e "${GREEN}  Removed Nginx site configuration${NC}"
else
    echo "  Nginx configuration not found, skipping..."
fi

# ============================================
# Step 3: Remove Cron Jobs
# ============================================
echo -e "${YELLOW}Step 3: Removing cron jobs...${NC}"

# Get current crontab and remove our entries
CRONTAB_BEFORE=$(crontab -l 2>/dev/null | wc -l || echo "0")
crontab -l 2>/dev/null | grep -v "octopus-agile-dashboard" | grep -v "fetch_prices.sh" | grep -v "fetch_consumption.sh" | grep -v "cleanup_old_data.sh" | crontab - 2>/dev/null || true
CRONTAB_AFTER=$(crontab -l 2>/dev/null | wc -l || echo "0")

if [ "$CRONTAB_BEFORE" != "$CRONTAB_AFTER" ]; then
    REMOVED_ITEMS+=("Cron jobs")
    echo -e "${GREEN}  Removed scheduled cron jobs${NC}"
else
    echo "  No cron jobs found to remove..."
fi

# ============================================
# Step 4: Remove PostgreSQL Database and User
# ============================================
echo -e "${YELLOW}Step 4: Removing PostgreSQL database...${NC}"

if command -v psql &> /dev/null; then
    # Check if PostgreSQL is running
    if sudo systemctl is-active --quiet postgresql 2>/dev/null; then
        # Drop database
        if sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw octopus_agile; then
            sudo -u postgres psql -c "DROP DATABASE octopus_agile;" 2>/dev/null || true
            echo -e "${GREEN}  Dropped database 'octopus_agile'${NC}"
        else
            echo "  Database 'octopus_agile' not found..."
        fi

        # Drop user
        if sudo -u postgres psql -c "SELECT 1 FROM pg_roles WHERE rolname='octopus'" 2>/dev/null | grep -q 1; then
            sudo -u postgres psql -c "DROP USER octopus;" 2>/dev/null || true
            echo -e "${GREEN}  Dropped user 'octopus'${NC}"
            REMOVED_ITEMS+=("PostgreSQL database and user")
        else
            echo "  User 'octopus' not found..."
        fi
    else
        echo "  PostgreSQL service not running, skipping..."
    fi
else
    echo "  PostgreSQL not installed, skipping..."
fi

# ============================================
# Step 5: Remove Python Virtual Environment
# ============================================
echo -e "${YELLOW}Step 5: Removing Python virtual environment...${NC}"

if [ -d "$PROJECT_DIR/backend/venv" ]; then
    rm -rf "$PROJECT_DIR/backend/venv"
    REMOVED_ITEMS+=("Python virtual environment")
    echo -e "${GREEN}  Removed backend/venv${NC}"
else
    echo "  Virtual environment not found, skipping..."
fi

# Also remove any Python cache
find "$PROJECT_DIR/backend" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find "$PROJECT_DIR/backend" -type f -name "*.pyc" -delete 2>/dev/null || true

# ============================================
# Step 6: Remove Frontend Build and Dependencies
# ============================================
echo -e "${YELLOW}Step 6: Removing frontend build and dependencies...${NC}"

if [ -d "$PROJECT_DIR/frontend/dist" ]; then
    rm -rf "$PROJECT_DIR/frontend/dist"
    echo -e "${GREEN}  Removed frontend/dist${NC}"
    REMOVED_ITEMS+=("Frontend build")
fi

if [ -d "$PROJECT_DIR/frontend/node_modules" ]; then
    rm -rf "$PROJECT_DIR/frontend/node_modules"
    echo -e "${GREEN}  Removed frontend/node_modules${NC}"
    REMOVED_ITEMS+=("Node modules")
else
    echo "  node_modules not found, skipping..."
fi

# Remove package-lock if you want a completely fresh install
if [ -f "$PROJECT_DIR/frontend/package-lock.json" ]; then
    rm -f "$PROJECT_DIR/frontend/package-lock.json"
    echo -e "${GREEN}  Removed package-lock.json${NC}"
fi

# ============================================
# Step 7: Remove Log Directory
# ============================================
echo -e "${YELLOW}Step 7: Removing log files...${NC}"

if [ -d ~/logs ]; then
    # Only remove logs related to this project
    rm -f ~/logs/fetch.log 2>/dev/null || true
    rm -f ~/logs/consumption.log 2>/dev/null || true
    rm -f ~/logs/cleanup.log 2>/dev/null || true

    # Remove logs directory if empty
    if [ -z "$(ls -A ~/logs 2>/dev/null)" ]; then
        rmdir ~/logs 2>/dev/null || true
        echo -e "${GREEN}  Removed ~/logs directory${NC}"
    else
        echo -e "${GREEN}  Removed project log files (directory not empty, kept)${NC}"
    fi
    REMOVED_ITEMS+=("Log files")
else
    echo "  Log directory not found, skipping..."
fi

# ============================================
# Step 8: Remove Docker Resources (if applicable)
# ============================================
echo -e "${YELLOW}Step 8: Checking for Docker resources...${NC}"

if command -v docker &> /dev/null; then
    DOCKER_REMOVED=false

    # Stop and remove containers
    for container in octopus-db octopus-redis octopus-backend octopus-frontend; do
        if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "^${container}$"; then
            docker stop "$container" 2>/dev/null || true
            docker rm "$container" 2>/dev/null || true
            echo -e "${GREEN}  Removed container: $container${NC}"
            DOCKER_REMOVED=true
        fi
    done

    # Remove volumes
    for volume in octopus-agile-dashboard_postgres_data octopus-agile-dashboard_redis_data postgres_data redis_data; do
        if docker volume ls --format '{{.Name}}' 2>/dev/null | grep -q "^${volume}$"; then
            docker volume rm "$volume" 2>/dev/null || true
            echo -e "${GREEN}  Removed volume: $volume${NC}"
            DOCKER_REMOVED=true
        fi
    done

    # Remove network
    if docker network ls --format '{{.Name}}' 2>/dev/null | grep -q "octopus-network"; then
        docker network rm octopus-network 2>/dev/null || true
        echo -e "${GREEN}  Removed network: octopus-network${NC}"
        DOCKER_REMOVED=true
    fi

    # Remove images
    for image in octopus-agile-dashboard-backend octopus-agile-dashboard-frontend octopus-agile-dashboard_backend octopus-agile-dashboard_frontend; do
        if docker images --format '{{.Repository}}' 2>/dev/null | grep -q "^${image}$"; then
            docker rmi "$image" 2>/dev/null || true
            echo -e "${GREEN}  Removed image: $image${NC}"
            DOCKER_REMOVED=true
        fi
    done

    if [ "$DOCKER_REMOVED" = true ]; then
        REMOVED_ITEMS+=("Docker resources")
    else
        echo "  No Docker resources found..."
    fi
else
    echo "  Docker not installed, skipping..."
fi

# ============================================
# Step 9: Remove Environment File
# ============================================
echo -e "${YELLOW}Step 9: Removing environment file...${NC}"

if [ -f "$PROJECT_DIR/.env" ]; then
    rm -f "$PROJECT_DIR/.env"
    REMOVED_ITEMS+=("Environment file")
    echo -e "${GREEN}  Removed .env file${NC}"
else
    echo "  .env file not found, skipping..."
fi

# ============================================
# Step 10: Optional - Remove Swap File
# ============================================
echo ""
echo -e "${YELLOW}Step 10: Swap file check...${NC}"

if [ -f /swapfile ]; then
    echo -e "${BLUE}A swap file exists at /swapfile${NC}"
    read -p "Do you want to remove it? (y/n): " REMOVE_SWAP
    if [ "$REMOVE_SWAP" = "y" ] || [ "$REMOVE_SWAP" = "Y" ]; then
        sudo swapoff /swapfile 2>/dev/null || true
        sudo rm -f /swapfile
        # Remove from fstab if present
        sudo sed -i '/\/swapfile/d' /etc/fstab 2>/dev/null || true
        REMOVED_ITEMS+=("Swap file")
        echo -e "${GREEN}  Removed swap file${NC}"
    else
        echo "  Keeping swap file..."
    fi
else
    echo "  No swap file found..."
fi

# ============================================
# Step 11: Optional - Remove System Packages
# ============================================
echo ""
echo -e "${YELLOW}Step 11: System packages...${NC}"
echo -e "${BLUE}The following packages were installed during setup:${NC}"
echo "  python3-pip, python3-venv, nodejs, npm, postgresql,"
echo "  postgresql-contrib, nginx, git, curl"
echo ""
echo -e "${RED}WARNING: Removing these may affect other applications!${NC}"
read -p "Do you want to remove system packages? (y/n): " REMOVE_PACKAGES

if [ "$REMOVE_PACKAGES" = "y" ] || [ "$REMOVE_PACKAGES" = "Y" ]; then
    echo ""
    echo -e "${YELLOW}Removing system packages...${NC}"

    # Stop services first
    sudo systemctl stop postgresql 2>/dev/null || true
    sudo systemctl stop nginx 2>/dev/null || true

    # Remove packages
    sudo apt remove -y python3-pip python3-venv nodejs npm postgresql postgresql-contrib nginx 2>/dev/null || true

    # Optional: also purge configuration
    read -p "Also purge configuration files? (y/n): " PURGE_CONFIG
    if [ "$PURGE_CONFIG" = "y" ] || [ "$PURGE_CONFIG" = "Y" ]; then
        sudo apt purge -y postgresql postgresql-contrib nginx 2>/dev/null || true
        sudo rm -rf /var/lib/postgresql 2>/dev/null || true
        sudo rm -rf /etc/postgresql 2>/dev/null || true
        sudo rm -rf /etc/nginx 2>/dev/null || true
    fi

    # Clean up
    sudo apt autoremove -y 2>/dev/null || true

    REMOVED_ITEMS+=("System packages")
    echo -e "${GREEN}  System packages removed${NC}"
else
    echo "  Keeping system packages..."
fi

# ============================================
# Summary
# ============================================
echo ""
echo "================================================"
echo -e "${GREEN}Purge Complete!${NC}"
echo "================================================"
echo ""

if [ ${#REMOVED_ITEMS[@]} -gt 0 ]; then
    echo -e "${GREEN}Removed:${NC}"
    for item in "${REMOVED_ITEMS[@]}"; do
        echo "  - $item"
    done
else
    echo "Nothing was removed."
fi

echo ""
echo -e "${BLUE}Note: The project source code remains in:${NC}"
echo "  $PROJECT_DIR"
echo ""
echo "To completely remove the project, run:"
echo "  rm -rf $PROJECT_DIR"
echo ""
echo -e "${YELLOW}If relocating to another device:${NC}"
echo "  1. Copy the project directory to the new device"
echo "  2. Run: ./scripts/setup_raspberry_pi.sh"
echo ""
