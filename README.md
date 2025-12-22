# Octopus Agile Dashboard

A full-stack application for visualising Octopus Energy Agile tariff prices and smart meter consumption data with interactive charts, optimised for deployment on a Raspberry Pi.

![Dashboard Preview](docs/dashboard-preview.png)

## Overview

This application provides real-time visualization of electricity prices and smart meter usage from Octopus Energy. It helps users on the Agile Octopus tariff optimise their energy consumption by showing when electricity is cheapest (or even negative - when you get paid to use power!).

**Key Value Proposition:** The Agile Octopus tariff changes prices every 30 minutes based on wholesale costs. This dashboard helps you:
- See current and upcoming prices at a glance
- Track your actual consumption against prices
- Identify the cheapest times to run high-power appliances
- Get alerted when negative "Plunge Pricing" occurs

## Features

### Price Visualization
- Real-time Agile tariff price display with color-coded pricing bands
- Interactive Plotly charts showing 24-48 hours of price data
- Negative price alerts (when you get PAID to use electricity!)
- Best upcoming times to use power highlighted

### Smart Meter Integration
- Half-hourly consumption tracking from your smart meter
- Dual y-axis charts comparing price vs usage
- Interactive AG Grid data table with filtering and sorting
- Clickable period summaries (Today, Week-to-Date, Month-to-Date)

### Summary Statistics
- Automatic calculation of totals and weighted averages
- Cost analysis based on actual consumption × price
- Historical comparison views

### Technical Features
- Dark theme interface optimised for readability
- Async data fetching for optimal performance
- PostgreSQL database caching for persistent storage
- Automatic database fallback (checks DB before API calls)
- In-memory caching (1 hour) for frequently accessed data
- Custom color schemes for data visualization
- Mobile-responsive design

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend                                 │
│              React + TypeScript + Plotly + AG Grid              │
│                    (Port 3000/5173)                             │
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
│  │ (Public)    │  │ API (Auth)  │  │ (In-memory + Postgres)  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Octopus Energy API                          │
│                  api.octopus.energy/v1/...                      │
└─────────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Software Requirements
- **Python**: 3.11 or higher
- **Node.js**: 18.x or higher
- **PostgreSQL**: 14.x or higher (optional, for persistent caching)
- **Git**: For version control

### Hardware Requirements (Raspberry Pi)
- Raspberry Pi 4 (2GB+ RAM recommended) or Pi 5
- 16GB+ microSD card
- Stable internet connection
- Power supply (official recommended)

### Octopus Energy Requirements
- Active Octopus Energy account
- Agile Octopus tariff (for dynamic pricing)
- Smart meter (SMETS2 preferred) for consumption data
- API key from your Octopus account dashboard

## Installation

### Quick Start (Development)

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/octopus-agile-dashboard.git
cd octopus-agile-dashboard

# Set up environment variables
cp .env.example .env
# Edit .env with your credentials (see Configuration section)

# Backend setup
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload

# Frontend setup (new terminal)
cd frontend
npm install
npm run dev
```

### Raspberry Pi Setup

#### 1. Prepare the Raspberry Pi

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y python3-pip python3-venv nodejs npm postgresql postgresql-contrib git nginx

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

#### 2. Configure PostgreSQL

```bash
# Create database user and database
sudo -u postgres psql

# In PostgreSQL prompt:
CREATE USER octopus WITH PASSWORD 'your_secure_password';
CREATE DATABASE octopus_agile;
GRANT ALL PRIVILEGES ON DATABASE octopus_agile TO octopus;
\q
```

#### 3. Clone and Configure

```bash
# Clone repository
cd ~
git clone https://github.com/YOUR_USERNAME/octopus-agile-dashboard.git
cd octopus-agile-dashboard

# Create environment file
cp .env.example .env
nano .env  # Edit with your credentials
```

#### 4. Backend Installation

```bash
cd backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Test the backend
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

#### 5. Frontend Installation

```bash
cd ~/octopus-agile-dashboard/frontend

# Install dependencies
npm install

# Build for production
npm run build
```

#### 6. Set Up Systemd Services

Create backend service:
```bash
sudo nano /etc/systemd/system/octopus-backend.service
```

```ini
[Unit]
Description=Octopus Agile Dashboard Backend
After=network.target postgresql.service

[Service]
User=pi
Group=pi
WorkingDirectory=/home/pi/octopus-agile-dashboard/backend
Environment="PATH=/home/pi/octopus-agile-dashboard/backend/venv/bin"
EnvironmentFile=/home/pi/octopus-agile-dashboard/.env
ExecStart=/home/pi/octopus-agile-dashboard/backend/venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

#### 7. Configure Nginx

```bash
sudo nano /etc/nginx/sites-available/octopus-agile
```

```nginx
server {
    listen 80;
    server_name raspberrypi.local _;

    # Frontend (built React app)
    location / {
        root /home/pi/octopus-agile-dashboard/frontend/dist;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_cache_bypass $http_upgrade;
    }
}
```

Enable the site:
```bash
sudo ln -s /etc/nginx/sites-available/octopus-agile /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default
sudo nginx -t
sudo systemctl restart nginx
```

#### 8. Start Services

```bash
sudo systemctl daemon-reload
sudo systemctl enable octopus-backend
sudo systemctl start octopus-backend

# Verify everything is running
sudo systemctl status octopus-backend
sudo systemctl status nginx
```

#### 9. Set Up Cron for Data Fetching

```bash
crontab -e
```

Add:
```cron
# Fetch prices every 30 minutes
*/30 * * * * /home/pi/octopus-agile-dashboard/scripts/fetch_prices.sh >> /home/pi/logs/fetch.log 2>&1

# Fetch consumption data every hour
0 * * * * /home/pi/octopus-agile-dashboard/scripts/fetch_consumption.sh >> /home/pi/logs/consumption.log 2>&1

# Daily cleanup of old cached data (keep 90 days)
0 3 * * * /home/pi/octopus-agile-dashboard/scripts/cleanup_old_data.sh >> /home/pi/logs/cleanup.log 2>&1
```

## Configuration

### Environment Variables

Create a `.env` file in the project root:

```bash
# Octopus Energy API Configuration
OCTOPUS_API_KEY=sk_live_your_api_key_here
MPAN=your_13_digit_mpan
SERIAL_NUMBER=your_meter_serial_number

# Region Configuration (H = Southern England/Southampton)
REGION=H

# Database Configuration
DATABASE_URL=postgresql://octopus:your_password@localhost:5432/octopus_agile

# Optional: Redis for additional caching
REDIS_URL=redis://localhost:6379/0

# Cache Settings
CACHE_TTL_SECONDS=3600
PRICE_FETCH_INTERVAL_MINUTES=30

# Server Configuration
API_HOST=0.0.0.0
API_PORT=8000
DEBUG=false

# Frontend Configuration
VITE_API_URL=http://localhost:8000
```

### Finding Your Octopus Energy Credentials

1. **API Key**: Log into [Octopus Energy](https://octopus.energy/dashboard/developer/), go to Developer Settings
2. **MPAN**: Found on your electricity bill or in your Octopus account under "Your Account" → "Meter details"
3. **Serial Number**: Listed alongside your MPAN in meter details

### Region Codes

| Code | Region |
|------|--------|
| A | Eastern England |
| B | East Midlands |
| C | London |
| D | Merseyside & North Wales |
| E | West Midlands |
| F | North Eastern England |
| G | North Western England |
| **H** | **Southern England (Southampton)** |
| J | South Eastern England |
| K | South Wales |
| L | South Western England |
| M | Yorkshire |
| N | Southern Scotland |
| P | Northern Scotland |

## Usage

### Accessing the Dashboard

- **Local (same network)**: `http://raspberrypi.local` or `http://<PI_IP_ADDRESS>`
- **Development**: `http://localhost:5173` (frontend) + `http://localhost:8000` (API)

### API Endpoints

#### Public Endpoints (No Auth Required)

```bash
# Get current Agile prices
GET /api/prices/current
GET /api/prices?period_from=2024-01-01&period_to=2024-01-02

# Get price statistics
GET /api/prices/stats

# Health check
GET /api/health
```

#### Authenticated Endpoints (Requires API Key)

```bash
# Get consumption data
GET /api/consumption?period_from=2024-01-01&period_to=2024-01-02

# Get combined price + consumption analysis
GET /api/analysis/cost?period_from=2024-01-01&period_to=2024-01-02
```

### Example API Calls

```python
import requests

# Get current prices (no auth needed)
response = requests.get("http://localhost:8000/api/prices/current")
prices = response.json()

# Get consumption (auth required)
response = requests.get(
    "http://localhost:8000/api/consumption",
    auth=("sk_live_your_api_key", "")  # Empty password
)
consumption = response.json()
```

```javascript
// Frontend: Using the custom hooks
import { usePrices, useConsumption } from './hooks';

function Dashboard() {
    const { data: prices, loading: pricesLoading } = usePrices();
    const { data: consumption, loading: consumptionLoading } = useConsumption();
    
    // Render your dashboard...
}
```

## Project Structure

```
octopus-agile-dashboard/
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── __init__.py
│   │   │   ├── prices.py          # Price endpoints
│   │   │   ├── consumption.py     # Consumption endpoints
│   │   │   └── analysis.py        # Combined analysis
│   │   ├── core/
│   │   │   ├── __init__.py
│   │   │   ├── config.py          # Settings management
│   │   │   └── cache.py           # Caching logic
│   │   ├── db/
│   │   │   ├── __init__.py
│   │   │   ├── database.py        # Database connection
│   │   │   └── models.py          # SQLAlchemy models
│   │   ├── services/
│   │   │   ├── __init__.py
│   │   │   ├── octopus_api.py     # Octopus Energy API client
│   │   │   └── calculations.py    # Price/cost calculations
│   │   └── main.py                # FastAPI application
│   ├── tests/
│   │   └── ...                    # Test files
│   ├── alembic/                   # Database migrations
│   ├── requirements.txt
│   └── alembic.ini
├── frontend/
│   ├── src/
│   │   ├── components/
│   │   │   ├── PriceChart.tsx     # Plotly price chart
│   │   │   ├── ConsumptionChart.tsx
│   │   │   ├── CurrentPrice.tsx   # Large price display
│   │   │   ├── StatsCards.tsx     # Statistics cards
│   │   │   └── DataTable.tsx      # AG Grid table
│   │   ├── hooks/
│   │   │   ├── usePrices.ts       # Price data hook
│   │   │   └── useConsumption.ts  # Consumption hook
│   │   ├── pages/
│   │   │   └── Dashboard.tsx      # Main dashboard
│   │   ├── services/
│   │   │   └── api.ts             # API client
│   │   ├── types/
│   │   │   └── index.ts           # TypeScript types
│   │   ├── utils/
│   │   │   └── formatters.ts      # Formatting utilities
│   │   ├── App.tsx
│   │   ├── main.tsx
│   │   └── index.css              # Tailwind + custom styles
│   ├── public/
│   ├── index.html
│   ├── package.json
│   ├── tsconfig.json
│   ├── vite.config.ts
│   └── tailwind.config.js
├── scripts/
│   ├── fetch_prices.sh            # Cron script for prices
│   ├── fetch_consumption.sh       # Cron script for consumption
│   ├── cleanup_old_data.sh        # Database cleanup
│   └── setup_raspberry_pi.sh      # Automated Pi setup
├── docs/
│   ├── API.md                     # API documentation
│   ├── DEPLOYMENT.md              # Deployment guide
│   └── dashboard-preview.png
├── .env.example
├── .gitignore
├── docker-compose.yml             # Docker setup (optional)
├── LICENSE
└── README.md
```

## Troubleshooting

### Common Issues

#### "No data available" on dashboard

```bash
# Check if backend is running
sudo systemctl status octopus-backend

# Manually fetch prices
cd ~/octopus-agile-dashboard/backend
source venv/bin/activate
python -c "from app.services.octopus_api import fetch_prices; print(fetch_prices())"
```

#### Database connection errors

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Verify database exists
sudo -u postgres psql -l | grep octopus

# Check connection string in .env
cat .env | grep DATABASE_URL
```

#### API authentication failures

```bash
# Test your API key directly
curl -u "sk_live_YOUR_KEY:" "https://api.octopus.energy/v1/products/"

# If that fails, regenerate your API key from the Octopus dashboard
```

#### "Cannot access from other devices"

```bash
# Check firewall
sudo ufw status
sudo ufw allow 80

# Get your Pi's IP
hostname -I

# Access via IP: http://192.168.1.XXX
```

#### High memory usage on Raspberry Pi

```bash
# Check memory
free -h

# Reduce PostgreSQL memory usage
sudo nano /etc/postgresql/14/main/postgresql.conf
# Set: shared_buffers = 128MB
# Set: work_mem = 4MB

sudo systemctl restart postgresql
```

### Log Files

```bash
# Backend logs
sudo journalctl -u octopus-backend -f

# Nginx logs
sudo tail -f /var/log/nginx/error.log

# Cron job logs
tail -f ~/logs/fetch.log
```

## Performance Optimization

### Caching Strategy

1. **In-memory cache**: 1-hour TTL for frequently accessed data
2. **PostgreSQL cache**: Persistent storage, checked before API calls
3. **Frontend cache**: React Query with 5-minute stale time

### Raspberry Pi Optimizations

```bash
# Increase swap (if running low on memory)
sudo dphys-swapfile swapoff
sudo nano /etc/dphys-swapfile  # Set CONF_SWAPSIZE=1024
sudo dphys-swapfile setup
sudo dphys-swapfile swapon

# Use tmpfs for logs
echo "tmpfs /home/pi/logs tmpfs defaults,noatime,size=50m 0 0" | sudo tee -a /etc/fstab
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow PEP 8 for Python code
- Use ESLint and Prettier for TypeScript
- Write tests for new features
- Update documentation as needed

### Ideas for Contributions

- [ ] Historical price charts with trends
- [ ] Price prediction using machine learning
- [ ] Telegram/WhatsApp notifications for price alerts
- [ ] Export data to CSV/Excel
- [ ] Integration with smart plugs for automated control
- [ ] Multi-region comparison view
- [ ] Gas tariff support
- [ ] Solar/battery integration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Octopus Energy](https://octopus.energy/) for their excellent API
- [Plotly](https://plotly.com/) for interactive charting
- [AG Grid](https://www.ag-grid.com/) for the data table
- [FastAPI](https://fastapi.tiangolo.com/) for the backend framework

## Support

- **Issues**: Open a GitHub issue for bugs or feature requests
- **Octopus Energy API**: [Developer Documentation](https://developer.octopus.energy/)
- **Community**: [Octopus Energy Forum](https://forum.octopus.energy/)

---

**Tip**: Add this dashboard to your phone's home screen for quick access - it works like a native app!
