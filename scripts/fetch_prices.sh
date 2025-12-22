#!/bin/bash
# ============================================
# Fetch Agile Prices Script
# Run this via cron to keep price data updated
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

# Run the price fetch
python -c "
import asyncio
from app.services.octopus_api import octopus_client
from datetime import datetime, timezone

async def fetch():
    print(f'[{datetime.now(timezone.utc).isoformat()}] Fetching prices...')
    prices = await octopus_client.fetch_current_prices()
    print(f'[{datetime.now(timezone.utc).isoformat()}] Fetched {len(prices)} price periods')
    
    # Check for negative prices
    negative = [p for p in prices if p['value_inc_vat'] < 0]
    if negative:
        print(f'⚡ ALERT: {len(negative)} negative price periods found!')
    
    return prices

asyncio.run(fetch())
"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Price fetch completed"
