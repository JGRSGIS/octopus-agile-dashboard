"""
API endpoints for combined price and consumption analysis.
Provides cost calculations and optimization insights.
"""

from fastapi import APIRouter, HTTPException, Query, Depends
from datetime import datetime, timedelta, timezone
from typing import Optional, Dict, Any, List
import logging

from app.services.octopus_api import octopus_client
from app.services.calculations import (
    calculate_price_statistics,
    calculate_consumption_statistics,
    calculate_cost_analysis,
    get_current_and_upcoming_prices,
)
from app.core.config import settings

logger = logging.getLogger(__name__)

router = APIRouter()


def check_full_config():
    """Verify full API is configured for analysis."""
    if not settings.OCTOPUS_API_KEY:
        raise HTTPException(
            status_code=503,
            detail="OCTOPUS_API_KEY not configured"
        )
    if not settings.MPAN or not settings.SERIAL_NUMBER:
        raise HTTPException(
            status_code=503,
            detail="MPAN and SERIAL_NUMBER must be configured for consumption data"
        )


@router.get("/cost")
async def get_cost_analysis(
    period_from: Optional[datetime] = Query(
        None,
        description="Start of period. Defaults to 7 days ago."
    ),
    period_to: Optional[datetime] = Query(
        None,
        description="End of period. Defaults to now."
    ),
    flat_rate_comparison: float = Query(
        24.50,
        description="Flat rate (p/kWh) to compare against. Default: 24.50p (typical SVT)"
    ),
    _: None = Depends(check_full_config),
) -> Dict[str, Any]:
    """
    Get cost analysis combining prices and consumption.
    
    Shows:
    - Total cost based on actual usage at actual prices
    - Comparison with a flat rate tariff
    - Breakdown by period
    - Best and worst usage times
    """
    try:
        # Default to last 7 days
        if period_from is None:
            period_from = datetime.now(timezone.utc) - timedelta(days=7)
        if period_to is None:
            period_to = datetime.now(timezone.utc)
        
        # Fetch both prices and consumption
        prices = await octopus_client.fetch_prices(
            period_from=period_from,
            period_to=period_to
        )
        
        consumption = await octopus_client.fetch_consumption(
            period_from=period_from,
            period_to=period_to
        )
        
        # Calculate cost analysis
        analysis = calculate_cost_analysis(prices, consumption, flat_rate_comparison)
        
        return {
            "region": settings.REGION,
            "mpan": settings.MPAN,
            "period_from": period_from.isoformat(),
            "period_to": period_to.isoformat(),
            "flat_rate_comparison_pence": flat_rate_comparison,
            **analysis.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error calculating cost analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/summary")
async def get_period_summary(
    period: str = Query(
        "today",
        description="Period: 'today', 'yesterday', 'week', 'month'"
    ),
    _: None = Depends(check_full_config),
) -> Dict[str, Any]:
    """
    Get summary statistics for common periods.
    
    Provides quick insights for Today, Yesterday, This Week, or This Month.
    """
    try:
        now = datetime.now(timezone.utc)
        
        # Calculate period boundaries
        if period == "today":
            period_from = now.replace(hour=0, minute=0, second=0, microsecond=0)
            period_to = now
            period_name = "Today"
        elif period == "yesterday":
            yesterday = now - timedelta(days=1)
            period_from = yesterday.replace(hour=0, minute=0, second=0, microsecond=0)
            period_to = period_from + timedelta(days=1)
            period_name = "Yesterday"
        elif period == "week":
            # Start of current week (Monday)
            days_since_monday = now.weekday()
            period_from = (now - timedelta(days=days_since_monday)).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            period_to = now
            period_name = "This Week"
        elif period == "month":
            period_from = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            period_to = now
            period_name = "This Month"
        else:
            raise HTTPException(
                status_code=400,
                detail="Invalid period. Use: today, yesterday, week, month"
            )
        
        # Fetch data
        prices = await octopus_client.fetch_prices(
            period_from=period_from,
            period_to=period_to
        )
        
        consumption = await octopus_client.fetch_consumption(
            period_from=period_from,
            period_to=period_to
        )
        
        # Calculate statistics
        price_stats = calculate_price_statistics(prices)
        consumption_stats = calculate_consumption_statistics(consumption)
        cost_analysis = calculate_cost_analysis(prices, consumption)
        
        return {
            "period": period_name,
            "period_from": period_from.isoformat(),
            "period_to": period_to.isoformat(),
            "prices": price_stats.to_dict(),
            "consumption": consumption_stats.to_dict(),
            "cost": cost_analysis.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting summary: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/dashboard")
async def get_dashboard_data(
    _: None = Depends(check_full_config),
) -> Dict[str, Any]:
    """
    Get all data needed for the main dashboard in a single request.
    
    Optimized for frontend to minimize API calls.
    """
    try:
        now = datetime.now(timezone.utc)
        
        # Fetch current prices (48 hour window)
        prices_from = now - timedelta(hours=24)
        prices_to = now + timedelta(hours=24)
        prices = await octopus_client.fetch_prices(
            period_from=prices_from,
            period_to=prices_to
        )
        
        # Fetch recent consumption (7 days)
        consumption_from = now - timedelta(days=7)
        consumption = await octopus_client.fetch_consumption(
            period_from=consumption_from,
            period_to=now
        )
        
        # Get current and upcoming
        current_prices = get_current_and_upcoming_prices(prices)
        
        # Calculate today's stats
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        today_prices = [
            p for p in prices
            if datetime.fromisoformat(
                p["valid_from"].replace("Z", "+00:00")
            ) >= today_start
        ]
        today_consumption = [
            c for c in consumption
            if datetime.fromisoformat(
                c["interval_start"].replace("Z", "+00:00")
            ) >= today_start
        ]
        
        price_stats = calculate_price_statistics(today_prices)
        consumption_stats = calculate_consumption_statistics(today_consumption)
        
        # Cost for matched periods
        cost_analysis = calculate_cost_analysis(prices, consumption)
        
        return {
            "timestamp": now.isoformat(),
            "region": settings.REGION,
            "current_price": current_prices["current"],
            "upcoming_prices": current_prices["upcoming"][:24],  # Next 12 hours
            "best_upcoming": current_prices["best_upcoming"],
            "has_negative_upcoming": current_prices["has_negative_upcoming"],
            "prices_48h": prices,
            "consumption_7d": consumption,
            "today": {
                "prices": price_stats.to_dict(),
                "consumption": consumption_stats.to_dict(),
            },
            "cost_analysis": cost_analysis.to_dict(),
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting dashboard data: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/recommendations")
async def get_usage_recommendations(
    hours_ahead: int = Query(
        24,
        ge=1,
        le=48,
        description="Hours ahead to analyze for recommendations"
    ),
) -> Dict[str, Any]:
    """
    Get recommendations for optimal electricity usage based on upcoming prices.
    
    Returns the best times to run high-power appliances.
    """
    try:
        now = datetime.now(timezone.utc)
        prices = await octopus_client.fetch_prices(
            period_from=now,
            period_to=now + timedelta(hours=hours_ahead)
        )
        
        if not prices:
            return {
                "message": "No upcoming price data available",
                "recommendations": [],
            }
        
        # Sort by price
        sorted_prices = sorted(prices, key=lambda x: x["value_inc_vat"])
        
        # Categorize recommendations
        very_cheap = [p for p in sorted_prices if p["value_inc_vat"] < 5]
        cheap = [p for p in sorted_prices if 5 <= p["value_inc_vat"] < 15]
        negative = [p for p in sorted_prices if p["value_inc_vat"] < 0]
        
        recommendations = []
        
        if negative:
            recommendations.append({
                "priority": "URGENT",
                "message": f"🎉 {len(negative)} periods with NEGATIVE prices! You get PAID to use electricity!",
                "periods": negative,
                "suggested_uses": [
                    "Charge electric vehicle",
                    "Run dishwasher/washing machine",
                    "Charge batteries/power banks",
                    "Heat water",
                ],
            })
        
        if very_cheap:
            recommendations.append({
                "priority": "HIGH",
                "message": f"⚡ {len(very_cheap)} periods under 5p/kWh - great time for high-power usage",
                "periods": very_cheap[:10],  # Top 10
                "suggested_uses": [
                    "EV charging",
                    "Laundry and drying",
                    "Baking/cooking",
                    "Running power tools",
                ],
            })
        
        if cheap:
            recommendations.append({
                "priority": "MEDIUM",
                "message": f"✓ {len(cheap)} periods between 5-15p/kWh - good value",
                "periods": cheap[:10],
                "suggested_uses": [
                    "General appliance use",
                    "Computer/gaming sessions",
                    "Vacuuming/cleaning",
                ],
            })
        
        # Find expensive periods to avoid
        expensive = [p for p in prices if p["value_inc_vat"] > 30]
        if expensive:
            recommendations.append({
                "priority": "AVOID",
                "message": f"🚫 {len(expensive)} expensive periods (>30p/kWh) - reduce usage",
                "periods": sorted(expensive, key=lambda x: x["valid_from"])[:10],
                "suggestions": [
                    "Delay high-power appliances",
                    "Switch off non-essential items",
                    "Use battery-stored power if available",
                ],
            })
        
        return {
            "hours_analyzed": hours_ahead,
            "total_periods": len(prices),
            "cheapest_period": sorted_prices[0] if sorted_prices else None,
            "most_expensive_period": sorted_prices[-1] if sorted_prices else None,
            "recommendations": recommendations,
        }
    
    except Exception as e:
        logger.error(f"Error generating recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))
