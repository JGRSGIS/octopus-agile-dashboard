"""
API endpoints for Agile tariff prices.
No authentication required - prices are public data.
"""

from fastapi import APIRouter, HTTPException, Query
from datetime import datetime, timedelta, timezone
from typing import Optional, List, Dict, Any
import logging

from app.services.octopus_api import octopus_client
from app.services.calculations import (
    calculate_price_statistics,
    get_current_and_upcoming_prices,
    aggregate_by_hour,
)
from app.core.config import settings

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("")
async def get_prices(
    period_from: Optional[datetime] = Query(
        None,
        description="Start of period (ISO format). Defaults to 24 hours ago."
    ),
    period_to: Optional[datetime] = Query(
        None,
        description="End of period (ISO format). Defaults to 24 hours from now."
    ),
    include_stats: bool = Query(
        True,
        description="Include statistics in response"
    ),
) -> Dict[str, Any]:
    """
    Get Agile tariff prices for a specified period.
    
    Returns half-hourly prices with optional statistics.
    """
    try:
        prices = await octopus_client.fetch_prices(
            period_from=period_from,
            period_to=period_to
        )
        
        response = {
            "region": settings.REGION,
            "product_code": settings.PRODUCT_CODE,
            "tariff_code": settings.tariff_code,
            "count": len(prices),
            "prices": prices,
        }
        
        if include_stats and prices:
            stats = calculate_price_statistics(prices)
            response["stats"] = stats.to_dict()
        
        return response
    
    except Exception as e:
        logger.error(f"Error fetching prices: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/current")
async def get_current_price() -> Dict[str, Any]:
    """
    Get the current price and upcoming periods.
    
    Includes:
    - Current half-hour price
    - Next 12 hours of prices
    - Best times to use power
    - Negative price alerts
    """
    try:
        prices = await octopus_client.fetch_current_prices()
        result = get_current_and_upcoming_prices(prices, hours_ahead=12)
        
        return {
            "region": settings.REGION,
            "product_code": settings.PRODUCT_CODE,
            "timestamp": datetime.now(timezone.utc).isoformat(),
            **result,
        }
    
    except Exception as e:
        logger.error(f"Error fetching current price: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/stats")
async def get_price_stats(
    period_from: Optional[datetime] = Query(
        None,
        description="Start of period. Defaults to 24 hours ago."
    ),
    period_to: Optional[datetime] = Query(
        None,
        description="End of period. Defaults to now."
    ),
) -> Dict[str, Any]:
    """
    Get price statistics for a period.
    
    Includes min, max, average, negative periods, and best/worst times.
    """
    try:
        # Default to last 24 hours for stats
        if period_from is None:
            period_from = datetime.now(timezone.utc) - timedelta(hours=24)
        if period_to is None:
            period_to = datetime.now(timezone.utc)
        
        prices = await octopus_client.fetch_prices(
            period_from=period_from,
            period_to=period_to
        )
        
        stats = calculate_price_statistics(prices)
        
        return {
            "region": settings.REGION,
            "period_from": period_from.isoformat(),
            "period_to": period_to.isoformat(),
            **stats.to_dict(),
        }
    
    except Exception as e:
        logger.error(f"Error calculating stats: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/hourly")
async def get_hourly_prices(
    period_from: Optional[datetime] = Query(
        None,
        description="Start of period. Defaults to 24 hours ago."
    ),
    period_to: Optional[datetime] = Query(
        None,
        description="End of period. Defaults to 24 hours from now."
    ),
) -> Dict[str, Any]:
    """
    Get hourly aggregated prices (average of two half-hour periods).
    
    Useful for simplified visualizations.
    """
    try:
        prices = await octopus_client.fetch_prices(
            period_from=period_from,
            period_to=period_to
        )
        
        hourly = aggregate_by_hour(prices)
        
        return {
            "region": settings.REGION,
            "count": len(hourly),
            "prices": hourly,
        }
    
    except Exception as e:
        logger.error(f"Error aggregating hourly prices: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/negative")
async def get_negative_prices(
    days: int = Query(7, ge=1, le=30, description="Number of days to look back"),
) -> Dict[str, Any]:
    """
    Get all negative price periods (Plunge Pricing) in the specified range.
    
    These are periods when you get PAID to use electricity!
    """
    try:
        period_from = datetime.now(timezone.utc) - timedelta(days=days)
        period_to = datetime.now(timezone.utc) + timedelta(hours=24)
        
        prices = await octopus_client.fetch_prices(
            period_from=period_from,
            period_to=period_to
        )
        
        negative_prices = [p for p in prices if p["value_inc_vat"] < 0]
        
        # Sort by price (most negative first)
        negative_prices.sort(key=lambda x: x["value_inc_vat"])
        
        return {
            "region": settings.REGION,
            "days_searched": days,
            "count": len(negative_prices),
            "total_value": sum(p["value_inc_vat"] for p in negative_prices),
            "prices": negative_prices,
        }
    
    except Exception as e:
        logger.error(f"Error fetching negative prices: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/products")
async def get_agile_products() -> Dict[str, Any]:
    """
    Get available Agile products.
    
    Useful for discovering current product codes.
    """
    try:
        products = await octopus_client.fetch_products()
        
        return {
            "count": len(products),
            "current_product_code": settings.PRODUCT_CODE,
            "products": products,
        }
    
    except Exception as e:
        logger.error(f"Error fetching products: {e}")
        raise HTTPException(status_code=500, detail=str(e))
