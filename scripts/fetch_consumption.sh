#!/bin/bash
# ============================================
# Fetch Consumption Data Script
# Run this via cron to update consumption data
# ============================================

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Activate virtual environment
source "$PROJECT_DIR/backend/venv/bin/activate"

# Load environment variables
if [ -f "$PROJECT_DIR/.env" ]; then
    export $(cat "$PROJECT_DIR/.env" | grep -v '^#' | xargs)
fi

# Change to backend directory
cd "$PROJECT_DIR/backend"

# Run the consumption fetch
python -c "
import asyncio
from app.services.octopus_api import octopus_client
from datetime import datetime, timezone, timedelta

async def fetch():
    print(f'[{datetime.now(timezone.utc).isoformat()}] Fetching consumption data...')
    
    # Fetch last 7 days
    period_from = datetime.now(timezone.utc) - timedelta(days=7)
    consumption = await octopus_client.fetch_consumption(period_from=period_from)
    
    print(f'[{datetime.now(timezone.utc).isoformat()}] Fetched {len(consumption)} consumption periods')
    
    if consumption:
        total = sum(c['consumption'] for c in consumption)
        print(f'Total consumption: {total:.2f} kWh')
    
    return consumption

asyncio.run(fetch())
"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Consumption fetch completed"
