# API Documentation

This document describes the REST API endpoints provided by the Octopus Agile Dashboard backend.

## Base URL

- **Development**: `http://localhost:8000/api`
- **Production**: `http://your-server/api`

## Authentication

Most endpoints are public. Consumption endpoints require your Octopus Energy API credentials to be configured in the `.env` file.

---

## Health Check

### GET /api/health

Check if the API is running and healthy.

**Response**
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "region": "H",
  "cache_enabled": true
}
```

---

## Prices API

### GET /api/prices

Get Agile tariff prices for a date range.

**Query Parameters**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| period_from | ISO 8601 datetime | No | Start of period |
| period_to | ISO 8601 datetime | No | End of period |

**Example Request**
```bash
curl "http://localhost:8000/api/prices?period_from=2024-01-01T00:00:00Z&period_to=2024-01-02T00:00:00Z"
```

**Response**
```json
{
  "prices": [
    {
      "value_exc_vat": 15.5,
      "value_inc_vat": 16.275,
      "valid_from": "2024-01-01T00:00:00Z",
      "valid_to": "2024-01-01T00:30:00Z"
    }
  ],
  "count": 48,
  "region": "H"
}
```

### GET /api/prices/current

Get the current price and upcoming periods.

**Response**
```json
{
  "current": {
    "value_exc_vat": 15.5,
    "value_inc_vat": 16.275,
    "valid_from": "2024-01-01T12:00:00Z",
    "valid_to": "2024-01-01T12:30:00Z"
  },
  "next_periods": [...],
  "min_upcoming": {...},
  "max_upcoming": {...}
}
```

### GET /api/prices/stats

Get price statistics for a period.

**Query Parameters**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| period_from | ISO 8601 datetime | No | Start of period |
| period_to | ISO 8601 datetime | No | End of period |

**Response**
```json
{
  "min": 5.2,
  "max": 35.8,
  "average": 18.5,
  "count": 48
}
```

### GET /api/prices/hourly

Get hourly aggregated prices.

### GET /api/prices/negative

Get periods with negative prices.

**Query Parameters**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| days | integer | 7 | Number of days to look back |

---

## Consumption API

These endpoints require Octopus Energy API credentials configured in `.env`.

### GET /api/consumption

Get consumption data for a date range.

**Query Parameters**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| period_from | ISO 8601 datetime | No | Start of period |
| period_to | ISO 8601 datetime | No | End of period |

**Response**
```json
{
  "consumption": [
    {
      "consumption": 0.523,
      "interval_start": "2024-01-01T00:00:00Z",
      "interval_end": "2024-01-01T00:30:00Z"
    }
  ],
  "count": 48
}
```

### GET /api/consumption/today

Get today's consumption data.

### GET /api/consumption/stats

Get consumption statistics.

### GET /api/consumption/daily

Get daily consumption totals.

**Query Parameters**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| days | integer | 30 | Number of days |

---

## Analysis API

### GET /api/analysis/dashboard

Get combined dashboard data in a single request.

**Response**
```json
{
  "current_price": {...},
  "prices": [...],
  "consumption": [...],
  "stats": {...},
  "recommendations": {...}
}
```

### GET /api/analysis/cost

Get cost analysis comparing Agile vs flat rate.

**Query Parameters**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| period_from | ISO 8601 datetime | No | Start of period |
| period_to | ISO 8601 datetime | No | End of period |
| flat_rate_comparison | number | No | Flat rate for comparison (p/kWh) |

### GET /api/analysis/summary

Get period summary statistics.

**Query Parameters**
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| period | string | Yes | One of: `today`, `yesterday`, `week`, `month` |

### GET /api/analysis/recommendations

Get usage recommendations based on upcoming prices.

**Query Parameters**
| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| hours_ahead | integer | 24 | Hours to look ahead |

---

## Error Responses

All endpoints return errors in this format:

```json
{
  "detail": "Error message describing what went wrong"
}
```

**Common HTTP Status Codes**
| Code | Description |
|------|-------------|
| 200 | Success |
| 400 | Bad Request - Invalid parameters |
| 404 | Not Found - Resource doesn't exist |
| 500 | Internal Server Error |
| 502 | Bad Gateway - Octopus API unavailable |

---

## Rate Limiting

The API implements caching to reduce load on the Octopus Energy API:
- Price data: Cached for 30 minutes
- Consumption data: Cached for 1 hour
- Database caching: Persistent storage for historical data

---

## Interactive Documentation

When running the backend, interactive API documentation is available at:
- **Swagger UI**: `http://localhost:8000/api/docs`
- **ReDoc**: `http://localhost:8000/api/redoc`
