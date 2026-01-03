# Live Electricity Monitoring with Octopus Home Mini

This guide explains how to enable real-time electricity monitoring in your Octopus Agile Dashboard using the Octopus Home Mini device.

## Overview

The Live Monitoring feature provides near real-time electricity consumption data by connecting to the Octopus Energy GraphQL API. This requires an **Octopus Home Mini** device connected to your smart meter.

### Features

- **Live Demand Display**: Current power usage in watts with color-coded levels
- **Rolling Consumption Chart**: 5-minute history with 10-second granularity
- **Live Cost Tracking**: Session costs and hourly/daily/monthly projections
- **Automatic Updates**: Data refreshes every 10 seconds

## Prerequisites

1. **Octopus Energy Account** with an active electricity supply
2. **Octopus Home Mini** device installed and connected to your smart meter
3. **Existing Dashboard Setup** - the base dashboard must already be running

### Getting an Octopus Home Mini

If you don't have a Home Mini:
- Request one free from Octopus Energy via the app or website
- It connects to your smart meter's Consumer Access Device (CAD) port
- Once installed, it uploads consumption data every 10 seconds

## Configuration

### Step 1: Find Your Account Number

Your Octopus account number can be found:
- On any Octopus Energy bill (top right)
- In the Octopus Energy app (Settings > Account)
- On the Octopus website dashboard

The format is: `A-XXXXXXXX` (A- followed by 8 alphanumeric characters)

### Step 2: Add Environment Variable

Add your account number to your `.env` file:

```bash
# Existing configuration
OCTOPUS_API_KEY=sk_live_xxxxxxxxxxxxxxxxxxxx
MPAN=2000000000000
SERIAL_NUMBER=00A0000000
REGION=H

# Add this line for live monitoring
OCTOPUS_ACCOUNT_NUMBER=A-1234ABCD
```

### Step 3: Restart Services

**Docker Compose:**
```bash
docker-compose down
docker-compose up -d --build
```

**Manual Setup:**
```bash
# Restart backend
cd backend
uvicorn app.main:app --reload

# Frontend (no restart needed if using hot reload)
```

## Using the Live Tab

Once configured, a new **"Live"** tab appears in the dashboard navigation with a pulsing green indicator.

### Live Demand Display

Shows current power consumption with color-coded levels:

| Power Level | Color | Description |
|-------------|-------|-------------|
| < 500W | Green | Low usage |
| 500-1000W | Blue | Normal usage |
| 1000-2000W | Yellow | Moderate usage |
| 2000-3000W | Orange | High usage |
| > 3000W | Red | Very high usage |

### Rolling Chart

Displays the last 5 minutes of power demand as a bar chart:
- Updates every 10 seconds
- Color-coded bars matching demand levels
- Hover for exact values

### Cost Tracking

Real-time cost calculations based on current Agile price:
- **Session Cost**: Total cost since page load
- **Current Rate**: Cost per hour at current demand
- **Projections**: Estimated daily/monthly costs

## API Endpoints

The live monitoring feature adds these API endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/live/status` | GET | Check if Home Mini is available |
| `/api/live/current` | GET | Get latest telemetry reading |
| `/api/live/telemetry` | GET | Get telemetry for time period |
| `/api/live/dashboard` | GET | Complete live dashboard data |
| `/api/live/stream` | GET | SSE stream for real-time updates |

### Query Parameters

**`/api/live/telemetry`**
- `minutes` (int, default: 5): Minutes of data to fetch (1-60)
- `grouping` (string, default: "TEN_SECONDS"): Data grouping interval

**`/api/live/stream`**
- `interval` (int, default: 10): Update interval in seconds (5-60)

### Example API Response

```json
{
  "timestamp": "2026-01-03T12:00:00Z",
  "available": true,
  "current": {
    "timestamp": "2026-01-03T12:00:00Z",
    "reading": {
      "read_at": "2026-01-03T11:59:50Z",
      "consumption_delta": 0.0023,
      "demand": 0.842,
      "cost_delta": 0.15,
      "consumption": 12.456
    },
    "current_demand_kw": 0.842,
    "current_demand_watts": 842
  },
  "recent_readings": [...],
  "stats": {
    "demand": {
      "current_kw": 0.842,
      "current_watts": 842,
      "average_kw": 0.756,
      "peak_kw": 2.341,
      "min_kw": 0.123
    },
    "consumption": {
      "total_kwh": 0.0632,
      "period_count": 30
    },
    "cost": {
      "total_pence": 4.23,
      "total_pounds": 0.04
    }
  }
}
```

## Rate Limits

The Octopus GraphQL API has rate limits:

- **100 calls per hour** (shared across all integrations)
- The dashboard polls every 10 seconds = ~360 calls/hour
- Other apps (Octopus app, Home Assistant) share this limit

### Recommendations

- Avoid running multiple integrations simultaneously
- The SSE stream is more efficient than polling
- Consider increasing the refresh interval if you hit limits

## Troubleshooting

### "Home Mini Not Available" Message

**Causes:**
1. `OCTOPUS_ACCOUNT_NUMBER` not configured
2. No Home Mini registered to your account
3. Home Mini offline or disconnected

**Solutions:**
- Verify account number in `.env`
- Check Home Mini status in Octopus app
- Ensure Home Mini has power and WiFi connection

### No Data Appearing

**Causes:**
1. Home Mini recently installed (may take 24h to start reporting)
2. API authentication failed
3. Rate limit exceeded

**Solutions:**
- Wait for Home Mini to start transmitting
- Verify `OCTOPUS_API_KEY` is correct
- Reduce polling frequency or stop other integrations

### Stale Data / Not Updating

**Causes:**
1. Network connectivity issues
2. Browser tab in background (reduced refresh rate)
3. Backend service crashed

**Solutions:**
- Check network connectivity
- Keep browser tab active
- Check backend logs: `docker-compose logs backend`

## Technical Details

### Authentication Flow

1. Backend obtains JWT token using API key via `obtainKrakenToken` mutation
2. Token cached for 55 minutes (expires at 60)
3. Device ID discovered from account via GraphQL query
4. Telemetry fetched using `smartMeterTelemetry` query

### Data Flow

```
Home Mini → Octopus Servers → GraphQL API → Backend → Frontend
   ↓              ↓               ↓            ↓          ↓
 10 sec       ~30 sec          On request    Cache     React Query
```

### Files Added

**Backend:**
- `backend/app/services/octopus_graphql.py` - GraphQL client
- `backend/app/api/live.py` - REST endpoints

**Frontend:**
- `frontend/src/components/LiveDemand.tsx` - Demand display
- `frontend/src/components/LiveConsumptionChart.tsx` - Rolling chart
- `frontend/src/components/LiveCostTracker.tsx` - Cost tracking
- `frontend/src/components/LiveTab.tsx` - Container component

## Further Reading

- [Octopus Energy API Documentation](https://developer.octopus.energy/)
- [GraphQL API Reference](https://developer.octopus.energy/graphql/reference/)
- [Home Mini Information](https://octopus.energy/blog/octopus-home-mini/)
