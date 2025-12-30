#!/bin/bash
# ============================================
# Cleanup Old Data Script
# Run this via cron to remove old cached data
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

# Default retention period (days)
RETENTION_DAYS=${RETENTION_DAYS:-90}

# Run the cleanup
python -c "
import asyncio
from datetime import datetime, timezone, timedelta
from sqlalchemy import text

async def cleanup():
    try:
        from app.db.database import engine

        cutoff_date = datetime.now(timezone.utc) - timedelta(days=$RETENTION_DAYS)
        print(f'[{datetime.now(timezone.utc).isoformat()}] Starting cleanup of data older than {cutoff_date.date()}...')

        async with engine.begin() as conn:
            # Clean up old price data
            result = await conn.execute(
                text('DELETE FROM prices WHERE valid_from < :cutoff'),
                {'cutoff': cutoff_date}
            )
            prices_deleted = result.rowcount

            # Clean up old consumption data
            result = await conn.execute(
                text('DELETE FROM consumption WHERE interval_start < :cutoff'),
                {'cutoff': cutoff_date}
            )
            consumption_deleted = result.rowcount

        print(f'[{datetime.now(timezone.utc).isoformat()}] Cleanup complete:')
        print(f'  - Deleted {prices_deleted} old price records')
        print(f'  - Deleted {consumption_deleted} old consumption records')

    except Exception as e:
        print(f'[{datetime.now(timezone.utc).isoformat()}] Cleanup error: {e}')
        raise

asyncio.run(cleanup())
"

echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] Database cleanup completed"
