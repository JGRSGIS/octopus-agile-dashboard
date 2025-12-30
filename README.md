# Octopus Agile Dashboard

A full-stack web application for visualising Octopus Energy Agile tariff prices and smart meter consumption data with interactive charts. Optimised for deployment on a Raspberry Pi.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
  - [Quick Start (Development)](#quick-start-development)
  - [Docker Deployment](#docker-deployment)
  - [Raspberry Pi Setup](#raspberry-pi-setup)
- [Configuration](#configuration)
  - [Environment Variables](#environment-variables)
  - [Finding Your Octopus Energy Credentials](#finding-your-octopus-energy-credentials)
  - [Region Codes](#region-codes)
- [Usage](#usage)
  - [Accessing the Dashboard](#accessing-the-dashboard)
  - [Code Examples](#code-examples)
- [API Documentation](#api-documentation)
  - [Public Endpoints](#public-endpoints)
  - [Authenticated Endpoints](#authenticated-endpoints)
  - [Analysis Endpoints](#analysis-endpoints)
- [Project Structure](#project-structure)
- [Troubleshooting](#troubleshooting)
- [Performance Optimisation](#performance-optimisation)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

The **Agile Octopus** tariff from Octopus Energy changes electricity prices every 30 minutes based on wholesale costs. This dashboard helps you make the most of dynamic pricing by:

- **Viewing current and upcoming prices** at a glance with colour-coded bands
- **Tracking actual consumption** against prices to understand your spending
- **Identifying the cheapest times** to run high-power appliances (washing machine, EV charging, etc.)
- **Getting alerted to negative "Plunge Pricing"** periods when you get **paid** to use electricity!

The application uses a modern tech stack with **FastAPI** (Python) on the backend and **React** (TypeScript) on the frontend, with **PostgreSQL** for persistent data storage.

---

## Features

### Price Visualisation
- Real-time Agile tariff price display with colour-coded pricing bands
- Interactive Plotly charts showing 24-48 hours of price data
- Negative price alerts highlighting when you get paid to use electricity
- Best upcoming times to use power clearly highlighted
- Hourly price aggregation for trend analysis

### Smart Meter Integration
- Half-hourly consumption tracking from your smart meter
- Dual y-axis charts comparing price vs usage patterns
- Interactive AG Grid data table with filtering and sorting
- Clickable period summaries (Today, Yesterday, Week-to-Date, Month-to-Date)

### Cost Analysis
- Automatic calculation of actual costs based on consumption x price
- Comparison against flat-rate tariffs to show savings
- Historical trend analysis
- Daily, weekly, and monthly cost breakdowns

### Technical Features
- Dark theme interface optimised for readability
- Mobile-responsive design for phone/tablet access
- Async data fetching for optimal performance
- Three-tier caching: In-memory (1 hour) → Redis (optional) → PostgreSQL
- Database-first approach (checks cache before API calls)
- Automatic data cleanup (90-day retention by default)

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend                                 │
│              React + TypeScript + Plotly + AG Grid              │
│                    (Port 80 via Nginx)                          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Backend                                 │
│                    FastAPI + Python 3.11+                       │
│                        (Port 8000)                              │
├─────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐  │
│  │ Price API   │  │ Consumption │  │ Caching Layer           │  │
│  │ (Public)    │  │ API (Auth)  │  │ (Memory + Redis + DB)   │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
┌───────────────────┐ ┌───────────────┐ ┌───────────────┐
│    PostgreSQL     │ │  Redis Cache  │ │ Octopus API   │
│   (Data Store)    │ │  (Optional)   │ │  (External)   │
└───────────────────┘ └───────────────┘ └───────────────┘
```

---

## Prerequisites

### Software Requirements

| Software | Version | Required |
|----------|---------|----------|
| Python | 3.11+ | Yes |
| Node.js | 18.x+ | Yes |
| PostgreSQL | 14.x+ | Yes |
| Git | Any recent | Yes |
| Docker & Docker Compose | Latest | Optional |

### Hardware Requirements (Raspberry Pi)

- Raspberry Pi 4 (2GB+ RAM recommended) or Pi 5
- 16GB+ microSD card
- Stable internet connection
- Official power supply

### Octopus Energy Requirements

- Active Octopus Energy account
- Agile Octopus tariff (for dynamic pricing)
- Smart meter (SMETS2 preferred) for consumption data
- API key from your Octopus account

---

## Installation

### Quick Start (Development)

**1. Clone the repository**

```bash
git clone https://github.com/YOUR_USERNAME/octopus-agile-dashboard.git
cd octopus-agile-dashboard
```

**2. Set up environment variables**

```bash
cp .env.example .env
# Edit .env with your credentials (see Configuration section)
```

**3. Set up PostgreSQL database**

```bash
# macOS
brew install postgresql && brew services start postgresql

# Ubuntu/Debian
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql

# Create database and user
sudo -u postgres psql -c "CREATE USER octopus WITH PASSWORD 'your_password';"
sudo -u postgres psql -c "CREATE DATABASE octopus_agile OWNER octopus;"
sudo -u postgres psql -c "GRANT ALL ON SCHEMA public TO octopus;"
```

**4. Start the backend**

```bash
cd backend
python3 -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
alembic upgrade head      # Run database migrations
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

**5. Start the frontend** (new terminal)

```bash
cd frontend
npm install
npm run dev
```

**6. Access the dashboard**

- Frontend: http://localhost:5173
- API Docs: http://localhost:8000/api/docs

---

### Docker Deployment

The easiest way to deploy the full stack:

**1. Configure environment**

```bash
cp .env.example .env
nano .env  # Add your Octopus Energy credentials
```

**2. Build and start all services**

```bash
docker-compose up -d
```

**3. Verify services are running**

```bash
docker-compose ps
docker-compose logs -f backend  # View backend logs
```

**4. Access the dashboard**

- Dashboard: http://localhost
- API: http://localhost:8000
- API Docs: http://localhost:8000/api/docs

**Docker Services:**

| Service | Image | Port | Description |
|---------|-------|------|-------------|
| frontend | nginx:alpine | 80 | React app served by Nginx |
| backend | python:3.11-slim | 8000 | FastAPI application |
| db | postgres:15-alpine | 5432 | PostgreSQL database |
| redis | redis:7-alpine | 6379 | Optional cache layer |

---

### Raspberry Pi Setup

#### Automated Installation (Recommended)

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/octopus-agile-dashboard.git
cd octopus-agile-dashboard

# Configure your credentials
cp .env.example .env
nano .env  # Add your Octopus API key, MPAN, and serial number

# Run automated setup
chmod +x scripts/setup_raspberry_pi.sh
./scripts/setup_raspberry_pi.sh
```

The script automatically:
1. Updates the system packages
2. Installs Python 3.11+, Node.js 18+, PostgreSQL, and Nginx
3. Creates the database and user
4. Sets up the Python virtual environment
5. Runs database migrations
6. Builds the frontend for production
7. Configures Nginx as a reverse proxy
8. Creates a systemd service for the backend
9. Sets up cron jobs for automatic data fetching

#### Manual Installation

<details>
<summary>Click to expand manual installation steps</summary>

**1. Prepare the Raspberry Pi**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y python3-pip python3-venv nodejs npm postgresql postgresql-contrib git nginx
sudo systemctl enable postgresql
sudo systemctl start postgresql
```

**2. Configure PostgreSQL**

```bash
sudo -u postgres psql <<EOF
CREATE USER octopus WITH PASSWORD 'your_secure_password';
CREATE DATABASE octopus_agile OWNER octopus;
GRANT ALL ON SCHEMA public TO octopus;
EOF
```

**3. Clone and configure**

```bash
cd ~
git clone https://github.com/YOUR_USERNAME/octopus-agile-dashboard.git
cd octopus-agile-dashboard
cp .env.example .env
nano .env  # Edit with your credentials
```

**4. Backend installation**

```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
alembic upgrade head
```

**5. Frontend installation**

```bash
cd ~/octopus-agile-dashboard/frontend
npm install
npm run build
```

**6. Create systemd service**

```bash
sudo tee /etc/systemd/system/octopus-backend.service > /dev/null <<EOF
[Unit]
Description=Octopus Agile Dashboard Backend
After=network.target postgresql.service

[Service]
User=$USER
Group=$USER
WorkingDirectory=$HOME/octopus-agile-dashboard/backend
Environment="PATH=$HOME/octopus-agile-dashboard/backend/venv/bin"
EnvironmentFile=$HOME/octopus-agile-dashboard/.env
ExecStart=$HOME/octopus-agile-dashboard/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable octopus-backend
sudo systemctl start octopus-backend
```

**7. Configure Nginx**

```bash
sudo tee /etc/nginx/sites-available/octopus-agile > /dev/null <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name _;

    # Frontend
    location / {
        root $HOME/octopus-agile-dashboard/frontend/dist;
        try_files \$uri \$uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/octopus-agile /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl restart nginx
```

**8. Set up cron jobs**

```bash
mkdir -p ~/logs
(crontab -l 2>/dev/null; cat <<EOF
# Fetch prices every 30 minutes
*/30 * * * * $HOME/octopus-agile-dashboard/scripts/fetch_prices.sh >> $HOME/logs/fetch.log 2>&1

# Fetch consumption every hour
0 * * * * $HOME/octopus-agile-dashboard/scripts/fetch_consumption.sh >> $HOME/logs/consumption.log 2>&1

# Clean up old data daily at 3 AM
0 3 * * * $HOME/octopus-agile-dashboard/scripts/cleanup_old_data.sh >> $HOME/logs/cleanup.log 2>&1
EOF
) | crontab -
```

</details>

---

## Configuration

### Environment Variables

Create a `.env` file in the project root with the following variables:

```bash
# ============================================
# Octopus Energy API Configuration (Required)
# ============================================

# Your API key from https://octopus.energy/dashboard/developer/
OCTOPUS_API_KEY=sk_live_your_api_key_here

# 13-digit Meter Point Administration Number
MPAN=2000000000000

# Electricity meter serial number
SERIAL_NUMBER=00A0000000

# Your DNO region code (A-P, see Region Codes below)
REGION=H

# ============================================
# Database Configuration (Required)
# ============================================

# PostgreSQL connection string (use asyncpg driver)
DATABASE_URL=postgresql+asyncpg://octopus:your_password@localhost:5432/octopus_agile

# ============================================
# Cache Settings (Optional)
# ============================================

# Enable/disable caching (default: true)
CACHE_ENABLED=true

# Cache TTL in seconds (default: 3600 = 1 hour)
CACHE_TTL_SECONDS=3600

# Redis URL for distributed caching (optional)
# REDIS_URL=redis://localhost:6379/0

# ============================================
# Server Configuration (Optional)
# ============================================

# API server binding
API_HOST=0.0.0.0
API_PORT=8000

# Debug mode (set to false in production)
DEBUG=false

# ============================================
# Frontend Configuration (Optional)
# ============================================

# API URL for the frontend (used during build)
VITE_API_URL=http://localhost:8000
```

### Finding Your Octopus Energy Credentials

1. **API Key**:
   - Log into [Octopus Energy](https://octopus.energy/dashboard/)
   - Navigate to **Developer Settings** or visit https://octopus.energy/dashboard/developer/
   - Your API key starts with `sk_live_`

2. **MPAN** (Meter Point Administration Number):
   - Found on your electricity bill
   - Or in your Octopus account under **Account** → **Meter details**
   - It's a 13-digit number

3. **Serial Number**:
   - Listed alongside your MPAN in meter details
   - Usually starts with letters followed by numbers

### Region Codes

Your region determines which Agile tariff prices apply to you:

| Code | Region | Code | Region |
|------|--------|------|--------|
| A | Eastern England | H | **Southern England** |
| B | East Midlands | J | South Eastern England |
| C | London | K | South Wales |
| D | Merseyside & North Wales | L | South Western England |
| E | West Midlands | M | Yorkshire |
| F | North Eastern England | N | Southern Scotland |
| G | North Western England | P | Northern Scotland |

---

## Usage

### Accessing the Dashboard

| Deployment | URL |
|------------|-----|
| Development | http://localhost:5173 |
| Docker | http://localhost |
| Raspberry Pi (local) | http://raspberrypi.local or http://\<PI_IP\> |

### Code Examples

#### Python - Fetching Current Prices

```python
import requests

# Public endpoint - no authentication required
response = requests.get("http://localhost:8000/api/prices/current")
data = response.json()

print(f"Current price: {data['current']['value_inc_vat']}p/kWh")
print(f"Valid until: {data['current']['valid_to']}")

# Show best upcoming time
if data.get('min_upcoming'):
    print(f"Best time: {data['min_upcoming']['valid_from']} "
          f"at {data['min_upcoming']['value_inc_vat']}p/kWh")
```

#### Python - Fetching Consumption Data

```python
import requests

# Consumption requires API key (configured in backend .env)
response = requests.get(
    "http://localhost:8000/api/consumption",
    params={
        "period_from": "2024-01-01T00:00:00Z",
        "period_to": "2024-01-02T00:00:00Z"
    }
)
data = response.json()

for reading in data['consumption']:
    print(f"{reading['interval_start']}: {reading['consumption']} kWh")
```

#### JavaScript/TypeScript - Using React Query Hooks

```typescript
import { useQuery } from '@tanstack/react-query';
import axios from 'axios';

// Custom hook for fetching prices
function usePrices() {
  return useQuery({
    queryKey: ['prices', 'current'],
    queryFn: async () => {
      const { data } = await axios.get('/api/prices/current');
      return data;
    },
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
}

// Usage in component
function PriceDisplay() {
  const { data, isLoading, error } = usePrices();

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error loading prices</div>;

  return (
    <div>
      <h2>Current Price</h2>
      <p>{data.current.value_inc_vat}p/kWh</p>
    </div>
  );
}
```

#### cURL - API Examples

```bash
# Get current prices
curl http://localhost:8000/api/prices/current

# Get prices for a specific date range
curl "http://localhost:8000/api/prices?period_from=2024-01-01T00:00:00Z&period_to=2024-01-02T00:00:00Z"

# Get price statistics
curl http://localhost:8000/api/prices/stats

# Get negative price periods (last 7 days)
curl "http://localhost:8000/api/prices/negative?days=7"

# Get cost analysis
curl "http://localhost:8000/api/analysis/cost?period_from=2024-01-01&period_to=2024-01-31&flat_rate_comparison=24.5"

# Get usage recommendations
curl "http://localhost:8000/api/analysis/recommendations?hours_ahead=12"

# Health check
curl http://localhost:8000/api/health
```

---

## API Documentation

Full interactive API documentation is available when the backend is running:

- **Swagger UI**: http://localhost:8000/api/docs
- **ReDoc**: http://localhost:8000/api/redoc

### Public Endpoints

These endpoints do not require authentication:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health` | Health check and service status |
| GET | `/api/prices` | Get prices for a date range |
| GET | `/api/prices/current` | Current price and upcoming periods |
| GET | `/api/prices/stats` | Price statistics (min, max, average) |
| GET | `/api/prices/hourly` | Hourly aggregated prices |
| GET | `/api/prices/negative` | Negative price periods |

**Example Response - `/api/prices/current`:**

```json
{
  "current": {
    "value_exc_vat": 15.5,
    "value_inc_vat": 16.275,
    "valid_from": "2024-01-15T12:00:00Z",
    "valid_to": "2024-01-15T12:30:00Z"
  },
  "next_periods": [...],
  "min_upcoming": {
    "value_inc_vat": 5.2,
    "valid_from": "2024-01-15T03:00:00Z"
  },
  "max_upcoming": {
    "value_inc_vat": 35.8,
    "valid_from": "2024-01-15T17:30:00Z"
  }
}
```

### Authenticated Endpoints

These endpoints require your Octopus Energy API credentials to be configured:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/consumption` | Consumption data for date range |
| GET | `/api/consumption/today` | Today's consumption |
| GET | `/api/consumption/stats` | Consumption statistics |
| GET | `/api/consumption/daily` | Daily consumption totals |

### Analysis Endpoints

Combined data and calculations:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/analysis/dashboard` | All dashboard data in one request |
| GET | `/api/analysis/cost` | Cost analysis vs flat rate |
| GET | `/api/analysis/summary` | Period summaries (today/week/month) |
| GET | `/api/analysis/recommendations` | Best times to use power |

**Common Query Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| period_from | ISO 8601 datetime | Start of period |
| period_to | ISO 8601 datetime | End of period |
| days | integer | Number of days (for rolling periods) |

For complete API documentation, see [docs/API.md](docs/API.md).

---

## Project Structure

```
octopus-agile-dashboard/
├── backend/                      # FastAPI Python backend
│   ├── app/
│   │   ├── main.py               # Application entry point
│   │   ├── api/
│   │   │   ├── prices.py         # Price endpoints
│   │   │   ├── consumption.py    # Consumption endpoints
│   │   │   └── analysis.py       # Analysis endpoints
│   │   ├── core/
│   │   │   ├── config.py         # Settings management
│   │   │   └── cache.py          # Caching logic
│   │   ├── db/
│   │   │   ├── database.py       # Database connection
│   │   │   └── models.py         # SQLAlchemy models
│   │   └── services/
│   │       ├── octopus_api.py    # Octopus API client
│   │       └── calculations.py   # Price calculations
│   ├── alembic/                  # Database migrations
│   ├── tests/                    # Test suite
│   ├── requirements.txt
│   ├── alembic.ini
│   └── Dockerfile
│
├── frontend/                     # React TypeScript frontend
│   ├── src/
│   │   ├── main.tsx              # Application entry
│   │   ├── App.tsx
│   │   ├── pages/
│   │   │   └── Dashboard.tsx     # Main dashboard
│   │   ├── components/
│   │   │   ├── CurrentPrice.tsx  # Price display
│   │   │   ├── PriceChart.tsx    # Plotly chart
│   │   │   ├── ConsumptionChart.tsx
│   │   │   ├── StatsCards.tsx    # Statistics
│   │   │   └── DataTable.tsx     # AG Grid table
│   │   ├── hooks/                # React Query hooks
│   │   ├── services/             # API client
│   │   ├── types/                # TypeScript types
│   │   └── utils/                # Utilities
│   ├── package.json
│   ├── vite.config.ts
│   ├── tailwind.config.js
│   └── Dockerfile
│
├── scripts/
│   ├── setup_raspberry_pi.sh     # Automated Pi setup
│   ├── fetch_prices.sh           # Cron: fetch prices
│   ├── fetch_consumption.sh      # Cron: fetch consumption
│   └── cleanup_old_data.sh       # Cron: database cleanup
│
├── docs/
│   ├── API.md                    # API documentation
│   └── DEPLOYMENT.md             # Deployment guide
│
├── docker-compose.yml            # Docker orchestration
├── .env.example                  # Environment template
├── LICENSE                       # MIT License
└── README.md
```

---

## Troubleshooting

### Common Issues

#### "No data available" on dashboard

```bash
# 1. Check if the backend is running
sudo systemctl status octopus-backend
curl http://localhost:8000/api/health

# 2. Manually trigger a price fetch
cd ~/octopus-agile-dashboard
source backend/venv/bin/activate
python -c "import asyncio; from app.services.octopus_api import OctopusClient; print(asyncio.run(OctopusClient().get_current_prices()))"

# 3. Check logs for errors
sudo journalctl -u octopus-backend -n 50
```

#### Database connection errors

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Verify database exists
sudo -u postgres psql -l | grep octopus

# Test connection manually
psql -h localhost -U octopus -d octopus_agile -c "SELECT 1;"

# Check .env connection string format
cat .env | grep DATABASE_URL
# Should be: postgresql+asyncpg://user:password@host:port/database
```

#### API authentication failures

```bash
# Test your Octopus API key directly
curl -u "sk_live_YOUR_KEY:" "https://api.octopus.energy/v1/products/"

# If 401 error: regenerate your API key from Octopus dashboard
# If timeout: check internet connection
```

#### Cannot access from other devices

```bash
# Check Nginx is listening on all interfaces
sudo ss -tlnp | grep nginx

# Verify firewall allows port 80
sudo ufw status
sudo ufw allow 80/tcp
sudo ufw allow 8000/tcp  # For direct API access

# Get your Pi's IP address
hostname -I
# Access via: http://192.168.x.x
```

#### High memory usage on Raspberry Pi

```bash
# Check current memory
free -h

# Reduce PostgreSQL memory (edit postgresql.conf)
sudo nano /etc/postgresql/15/main/postgresql.conf
# Set: shared_buffers = 128MB
# Set: work_mem = 4MB

sudo systemctl restart postgresql

# Add swap space if needed
sudo dphys-swapfile swapoff
sudo sed -i 's/CONF_SWAPSIZE=.*/CONF_SWAPSIZE=1024/' /etc/dphys-swapfile
sudo dphys-swapfile setup
sudo dphys-swapfile swapon
```

#### Frontend build fails on Raspberry Pi

```bash
# Check Node.js version (need 18+)
node --version

# Increase Node memory limit for build
export NODE_OPTIONS="--max-old-space-size=2048"
npm run build

# Or use swap space during build
```

### Log Files

```bash
# Backend logs (systemd)
sudo journalctl -u octopus-backend -f

# Nginx access/error logs
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log

# Cron job logs
tail -f ~/logs/fetch.log
tail -f ~/logs/consumption.log

# Docker logs
docker-compose logs -f backend
docker-compose logs -f frontend
```

---

## Performance Optimisation

### Caching Strategy

The application uses a three-tier caching approach:

1. **In-memory cache** (1-hour TTL) - Fastest, for frequently accessed data
2. **Redis cache** (optional) - For distributed/multi-instance deployments
3. **PostgreSQL database** - Persistent storage, checked before external API calls

### Raspberry Pi Optimisations

```bash
# Use tmpfs for log files (reduces SD card wear)
echo "tmpfs /home/$USER/logs tmpfs defaults,noatime,size=50m 0 0" | sudo tee -a /etc/fstab
sudo mount -a

# Enable zram for better memory management
sudo apt install zram-tools
echo "ALGO=zstd" | sudo tee -a /etc/default/zramswap
sudo systemctl restart zramswap
```

### Database Optimisation

```sql
-- Run VACUUM periodically (automated via cleanup script)
VACUUM ANALYZE cached_prices;
VACUUM ANALYZE cached_consumption;

-- Check index usage
SELECT indexrelname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE schemaname = 'public';
```

---

## Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/amazing-feature`
3. **Commit** your changes: `git commit -m 'Add amazing feature'`
4. **Push** to the branch: `git push origin feature/amazing-feature`
5. **Open** a Pull Request

### Development Guidelines

- **Python**: Follow PEP 8, use `black` for formatting, `ruff` for linting
- **TypeScript**: Use ESLint configuration provided, run `npm run lint`
- **Testing**: Add tests for new features, run `pytest` for backend
- **Documentation**: Update README and API docs for new endpoints

### Code Quality Tools

```bash
# Backend
cd backend
black .                    # Format code
ruff check .               # Lint
mypy .                     # Type checking
pytest                     # Run tests

# Frontend
cd frontend
npm run lint               # ESLint
npm run type-check         # TypeScript check
```

### Ideas for Contributions

- Historical price trend charts with predictions
- Push notifications for price alerts (Telegram, Discord, etc.)
- Export data to CSV/Excel
- Smart plug integration for automated appliance control
- Multi-meter support for gas tariffs
- Solar/battery system integration
- Weather correlation analysis

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Acknowledgments

- [Octopus Energy](https://octopus.energy/) for their excellent public API
- [Plotly](https://plotly.com/) for interactive charting
- [AG Grid](https://www.ag-grid.com/) for the data table component
- [FastAPI](https://fastapi.tiangolo.com/) for the modern Python web framework
- [Tailwind CSS](https://tailwindcss.com/) for utility-first styling

## Support

- **Issues**: [Open a GitHub issue](../../issues) for bugs or feature requests
- **Octopus API**: [Developer Documentation](https://developer.octopus.energy/)
- **Community**: [Octopus Energy Forum](https://forum.octopus.energy/)

---

**Pro Tip**: Add this dashboard to your phone's home screen for quick access - it works like a native app thanks to responsive design!
