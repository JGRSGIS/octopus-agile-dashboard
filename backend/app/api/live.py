"""
Live electricity monitoring API endpoints.
Provides real-time telemetry data from Octopus Home Mini device.
"""

import asyncio
import logging
from datetime import UTC, datetime, timedelta
from typing import AsyncGenerator

from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import StreamingResponse
from pydantic import BaseModel

from app.services.octopus_graphql import graphql_client

logger = logging.getLogger(__name__)

router = APIRouter()


# ============ Response Models ============


class TelemetryReading(BaseModel):
    """Single telemetry reading from Home Mini."""

    read_at: str
    consumption_delta: float | None  # kWh consumed in period
    demand: float | None  # Current power demand in watts
    cost_delta: float | None  # Cost in period (pence)
    consumption: float | None  # Cumulative consumption


class LiveStatusResponse(BaseModel):
    """Status of live monitoring capability."""

    available: bool
    device_id: str | None
    message: str


class LatestReadingResponse(BaseModel):
    """Latest telemetry reading."""

    timestamp: str
    reading: TelemetryReading | None
    current_demand_kw: float | None
    current_demand_watts: int | None


class TelemetryResponse(BaseModel):
    """Telemetry data response."""

    device_id: str | None
    start: str
    end: str
    grouping: str
    count: int
    readings: list[TelemetryReading]
    summary: dict | None


class LiveDashboardResponse(BaseModel):
    """Complete live dashboard data."""

    timestamp: str
    available: bool
    current: LatestReadingResponse | None
    recent_readings: list[TelemetryReading]
    stats: dict | None


# ============ Helper Functions ============


def transform_telemetry(raw: dict) -> TelemetryReading:
    """Transform raw GraphQL response to TelemetryReading."""
    return TelemetryReading(
        read_at=raw.get("readAt", ""),
        consumption_delta=raw.get("consumptionDelta"),
        demand=raw.get("demand"),
        cost_delta=raw.get("costDelta"),
        consumption=raw.get("consumption"),
    )


def calculate_stats(readings: list[TelemetryReading]) -> dict:
    """Calculate statistics from telemetry readings."""
    if not readings:
        return {}

    demands = [r.demand for r in readings if r.demand is not None]
    consumptions = [r.consumption_delta for r in readings if r.consumption_delta is not None]
    costs = [r.cost_delta for r in readings if r.cost_delta is not None]

    stats = {}

    if demands:
        # API returns demand in watts, convert to kW for kw fields
        stats["demand"] = {
            "current_kw": demands[-1] / 1000 if demands else None,
            "current_watts": int(demands[-1]) if demands else None,
            "average_kw": sum(demands) / len(demands) / 1000,
            "peak_kw": max(demands) / 1000,
            "min_kw": min(demands) / 1000,
        }

    if consumptions:
        total_kwh = sum(consumptions)
        stats["consumption"] = {
            "total_kwh": total_kwh,
            "period_count": len(consumptions),
        }

    if costs:
        total_cost = sum(costs)
        stats["cost"] = {
            "total_pence": total_cost,
            "total_pounds": total_cost / 100,
        }

    return stats


# ============ API Endpoints ============


@router.get("/status", response_model=LiveStatusResponse)
async def get_live_status():
    """
    Check if live monitoring is available.
    Returns whether a Home Mini device is configured and accessible.
    """
    try:
        available = await graphql_client.check_home_mini_available()
        device_id = graphql_client._device_id

        if available:
            return LiveStatusResponse(
                available=True,
                device_id=device_id,
                message="Home Mini device is available for live monitoring",
            )
        else:
            return LiveStatusResponse(
                available=False,
                device_id=None,
                message="No Home Mini device found. Please ensure OCTOPUS_ACCOUNT_NUMBER is configured and you have a Home Mini installed.",
            )
    except Exception as e:
        logger.error(f"Error checking live status: {e}")
        return LiveStatusResponse(
            available=False,
            device_id=None,
            message=f"Error checking device status: {str(e)}",
        )


@router.get("/current", response_model=LatestReadingResponse)
async def get_current_reading():
    """
    Get the most recent telemetry reading.
    Returns current power demand and consumption.
    """
    try:
        reading = await graphql_client.get_latest_reading()

        if reading:
            transformed = transform_telemetry(reading)
            # API returns demand in watts, convert to kW for kw field
            demand_watts = int(transformed.demand) if transformed.demand is not None else None
            demand_kw = transformed.demand / 1000 if transformed.demand is not None else None

            return LatestReadingResponse(
                timestamp=datetime.now(UTC).isoformat(),
                reading=transformed,
                current_demand_kw=demand_kw,
                current_demand_watts=demand_watts,
            )
        else:
            return LatestReadingResponse(
                timestamp=datetime.now(UTC).isoformat(),
                reading=None,
                current_demand_kw=None,
                current_demand_watts=None,
            )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error fetching current reading: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch current reading")


@router.get("/telemetry", response_model=TelemetryResponse)
async def get_telemetry(
    minutes: int = Query(default=5, ge=1, le=60, description="Number of minutes of data to fetch"),
    grouping: str = Query(default="TEN_SECONDS", description="Grouping interval"),
):
    """
    Get telemetry data for the specified time period.
    Default is last 5 minutes with 10-second granularity.
    """
    try:
        end = datetime.now(UTC)
        start = end - timedelta(minutes=minutes)

        readings = await graphql_client.get_telemetry(
            start=start,
            end=end,
            grouping=grouping,
        )

        transformed = [transform_telemetry(r) for r in readings]
        stats = calculate_stats(transformed)

        return TelemetryResponse(
            device_id=graphql_client._device_id,
            start=start.isoformat(),
            end=end.isoformat(),
            grouping=grouping,
            count=len(transformed),
            readings=transformed,
            summary=stats if stats else None,
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error fetching telemetry: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch telemetry data")


@router.get("/dashboard", response_model=LiveDashboardResponse)
async def get_live_dashboard():
    """
    Get complete live dashboard data.
    Includes current reading, recent history, and statistics.
    """
    try:
        available = await graphql_client.check_home_mini_available()

        if not available:
            return LiveDashboardResponse(
                timestamp=datetime.now(UTC).isoformat(),
                available=False,
                current=None,
                recent_readings=[],
                stats=None,
            )

        # Fetch last 5 minutes of data
        end = datetime.now(UTC)
        start = end - timedelta(minutes=5)

        readings = await graphql_client.get_telemetry(
            start=start,
            end=end,
            grouping="TEN_SECONDS",
        )

        transformed = [transform_telemetry(r) for r in readings]
        stats = calculate_stats(transformed)

        # Get current reading (latest in the list)
        current = None
        if transformed:
            latest = transformed[-1]
            # API returns demand in watts, convert to kW for kw field
            demand_watts = int(latest.demand) if latest.demand is not None else None
            demand_kw = latest.demand / 1000 if latest.demand is not None else None
            current = LatestReadingResponse(
                timestamp=datetime.now(UTC).isoformat(),
                reading=latest,
                current_demand_kw=demand_kw,
                current_demand_watts=demand_watts,
            )

        return LiveDashboardResponse(
            timestamp=datetime.now(UTC).isoformat(),
            available=True,
            current=current,
            recent_readings=transformed,
            stats=stats,
        )

    except Exception as e:
        logger.error(f"Error fetching live dashboard: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch live dashboard data")


@router.get("/stream")
async def stream_telemetry(
    interval: int = Query(default=10, ge=5, le=60, description="Update interval in seconds"),
):
    """
    Server-Sent Events stream for real-time telemetry updates.
    Streams the latest reading at the specified interval.

    Note: Octopus API has rate limits (100 calls/hour shared).
    Minimum recommended interval is 10 seconds.
    """

    async def event_generator() -> AsyncGenerator[str, None]:
        """Generate SSE events with telemetry data."""
        while True:
            try:
                reading = await graphql_client.get_latest_reading()

                if reading:
                    transformed = transform_telemetry(reading)
                    # API returns demand in watts, convert to kW for kw field
                    demand_watts = int(transformed.demand) if transformed.demand is not None else None
                    demand_kw = transformed.demand / 1000 if transformed.demand is not None else None

                    # Format as SSE event
                    import json

                    data = {
                        "timestamp": datetime.now(UTC).isoformat(),
                        "read_at": transformed.read_at,
                        "demand_kw": demand_kw,
                        "demand_watts": demand_watts,
                        "consumption_delta": transformed.consumption_delta,
                        "cost_delta": transformed.cost_delta,
                    }
                    yield f"data: {json.dumps(data)}\n\n"
                else:
                    yield f"data: {json.dumps({'error': 'No reading available'})}\n\n"

            except Exception as e:
                logger.error(f"Error in SSE stream: {e}")
                yield f"data: {json.dumps({'error': str(e)})}\n\n"

            await asyncio.sleep(interval)

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )
