"""Services module for API clients and business logic."""

from app.services.calculations import (
    ConsumptionStatistics,
    CostAnalysis,
    PriceStatistics,
    aggregate_by_hour,
    calculate_consumption_statistics,
    calculate_cost_analysis,
    calculate_price_statistics,
    get_current_and_upcoming_prices,
)
from app.services.octopus_api import OctopusAPIClient, octopus_client

__all__ = [
    "ConsumptionStatistics",
    "CostAnalysis",
    "OctopusAPIClient",
    "PriceStatistics",
    "aggregate_by_hour",
    "calculate_consumption_statistics",
    "calculate_cost_analysis",
    "calculate_price_statistics",
    "get_current_and_upcoming_prices",
    "octopus_client",
]
