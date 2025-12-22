"""Services module for API clients and business logic."""

from app.services.octopus_api import OctopusAPIClient, octopus_client
from app.services.calculations import (
    calculate_price_statistics,
    calculate_consumption_statistics,
    calculate_cost_analysis,
    get_current_and_upcoming_prices,
    aggregate_by_hour,
    PriceStatistics,
    ConsumptionStatistics,
    CostAnalysis,
)

__all__ = [
    "OctopusAPIClient",
    "octopus_client",
    "calculate_price_statistics",
    "calculate_consumption_statistics",
    "calculate_cost_analysis",
    "get_current_and_upcoming_prices",
    "aggregate_by_hour",
    "PriceStatistics",
    "ConsumptionStatistics",
    "CostAnalysis",
]
