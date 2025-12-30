"""
API endpoints for smart meter consumption data.
Requires authentication with Octopus Energy API key.
"""

import logging
from datetime import UTC, datetime, timedelta
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query

from app.core.config import settings
from app.services.calculations import (
    aggregate_by_hour,
    calculate_consumption_statistics,
)
from app.services.octopus_api import octopus_client

logger = logging.getLogger(__name__)

router = APIRouter()


def check_consumption_config():
    """Verify consumption API is configured."""
    if not settings.OCTOPUS_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="OCTOPUS_API_KEY not configured. Add it to your .env file.",
        )
    if not settings.MPAN:
        raise HTTPException(
            status_code=503, detail="MPAN not configured. Add it to your .env file."
        )
    if not settings.SERIAL_NUMBER:
        raise HTTPException(
            status_code=503,
            detail="SERIAL_NUMBER not configured. Add it to your .env file.",
        )


@router.get("")
async def get_consumption(
    period_from: datetime | None = Query(
        None, description="Start of period (ISO format). Defaults to 7 days ago."
    ),
    period_to: datetime | None = Query(
        None, description="End of period (ISO format). Defaults to now."
    ),
    include_stats: bool = Query(True, description="Include statistics in response"),
    _: None = Depends(check_consumption_config),
) -> dict[str, Any]:
    """
    Get smart meter consumption data for a specified period.

    Returns half-hourly consumption in kWh with optional statistics.

    Note: Consumption data may have a delay of 24-48 hours from Octopus Energy.
    """
    try:
        consumption = await octopus_client.fetch_consumption(
            period_from=period_from, period_to=period_to
        )

        response = {
            "mpan": settings.MPAN,
            "serial_number": settings.SERIAL_NUMBER,
            "count": len(consumption),
            "consumption": consumption,
        }

        if include_stats and consumption:
            stats = calculate_consumption_statistics(consumption)
            response["stats"] = stats.to_dict()

        return response

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching consumption: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/today")
async def get_today_consumption(
    _: None = Depends(check_consumption_config),
) -> dict[str, Any]:
    """
    Get today's consumption data.

    Note: Data may not be complete until 24-48 hours after the period ends.
    """
    try:
        # Get from midnight today
        now = datetime.now(UTC)
        period_from = now.replace(hour=0, minute=0, second=0, microsecond=0)

        consumption = await octopus_client.fetch_consumption(
            period_from=period_from, period_to=now
        )

        stats = calculate_consumption_statistics(consumption)

        return {
            "date": period_from.strftime("%Y-%m-%d"),
            "count": len(consumption),
            "consumption": consumption,
            "stats": stats.to_dict(),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching today's consumption: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats")
async def get_consumption_stats(
    period_from: datetime | None = Query(
        None, description="Start of period. Defaults to 30 days ago."
    ),
    period_to: datetime | None = Query(
        None, description="End of period. Defaults to now."
    ),
    _: None = Depends(check_consumption_config),
) -> dict[str, Any]:
    """
    Get consumption statistics for a period.

    Includes totals, averages, peak usage, and daily breakdown.
    """
    try:
        # Default to last 30 days
        if period_from is None:
            period_from = datetime.now(UTC) - timedelta(days=30)
        if period_to is None:
            period_to = datetime.now(UTC)

        consumption = await octopus_client.fetch_consumption(
            period_from=period_from, period_to=period_to
        )

        stats = calculate_consumption_statistics(consumption)

        return {
            "mpan": settings.MPAN,
            "period_from": period_from.isoformat(),
            "period_to": period_to.isoformat(),
            **stats.to_dict(),
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error calculating consumption stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/hourly")
async def get_hourly_consumption(
    period_from: datetime | None = Query(
        None, description="Start of period. Defaults to 7 days ago."
    ),
    period_to: datetime | None = Query(
        None, description="End of period. Defaults to now."
    ),
    _: None = Depends(check_consumption_config),
) -> dict[str, Any]:
    """
    Get hourly aggregated consumption (sum of two half-hour periods).

    Useful for simplified visualizations and matching to hourly price data.
    """
    try:
        consumption = await octopus_client.fetch_consumption(
            period_from=period_from, period_to=period_to
        )

        # Aggregate to hourly
        hourly = aggregate_by_hour(
            consumption, value_key="consumption", time_key="interval_start"
        )

        # For consumption, we want sum not average
        for h in hourly:
            h["total"] = h["average"] * h["count"]
            del h["average"]

        return {
            "mpan": settings.MPAN,
            "count": len(hourly),
            "consumption": hourly,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error aggregating hourly consumption: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/daily")
async def get_daily_consumption(
    days: int = Query(30, ge=1, le=365, description="Number of days to retrieve"),
    _: None = Depends(check_consumption_config),
) -> dict[str, Any]:
    """
    Get daily consumption totals for the specified number of days.

    Returns total kWh for each day.
    """
    try:
        period_from = datetime.now(UTC) - timedelta(days=days)
        period_to = datetime.now(UTC)

        consumption = await octopus_client.fetch_consumption(
            period_from=period_from, period_to=period_to
        )

        stats = calculate_consumption_statistics(consumption)

        # Sort daily breakdown by date
        daily = [
            {"date": date, "kwh": kwh}
            for date, kwh in sorted(stats.daily_breakdown.items())
        ]

        return {
            "mpan": settings.MPAN,
            "days": days,
            "count": len(daily),
            "total_kwh": stats.total_kwh,
            "daily": daily,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting daily consumption: {e}")
        raise HTTPException(status_code=500, detail=str(e))
