"""
Calculations for price statistics, cost analysis, and data aggregation.
"""

import logging
from dataclasses import dataclass
from datetime import UTC, datetime, timedelta
from typing import Any

logger = logging.getLogger(__name__)


@dataclass
class PriceStatistics:
    """Statistics for a set of price periods."""

    count: int
    average: float
    minimum: float
    maximum: float
    negative_count: int
    total_negative_value: float
    cheapest_periods: list[dict[str, Any]]
    most_expensive_periods: list[dict[str, Any]]

    def to_dict(self) -> dict[str, Any]:
        return {
            "count": self.count,
            "average": round(self.average, 2),
            "minimum": round(self.minimum, 2),
            "maximum": round(self.maximum, 2),
            "negative_count": self.negative_count,
            "total_negative_value": round(self.total_negative_value, 2),
            "cheapest_periods": self.cheapest_periods[:5],
            "most_expensive_periods": self.most_expensive_periods[:5],
        }


@dataclass
class ConsumptionStatistics:
    """Statistics for consumption data."""

    total_kwh: float
    period_count: int
    average_per_period: float
    peak_consumption: float
    peak_period: dict[str, Any] | None
    daily_breakdown: dict[str, float]

    def to_dict(self) -> dict[str, Any]:
        return {
            "total_kwh": round(self.total_kwh, 3),
            "period_count": self.period_count,
            "average_per_period": round(self.average_per_period, 3),
            "peak_consumption": round(self.peak_consumption, 3),
            "peak_period": self.peak_period,
            "daily_breakdown": {
                k: round(v, 3) for k, v in self.daily_breakdown.items()
            },
        }


@dataclass
class CostAnalysis:
    """Combined analysis of prices and consumption."""

    total_cost_pence: float
    total_kwh: float
    weighted_average_price: float
    savings_vs_flat_rate: float
    cost_by_period: list[dict[str, Any]]
    cheapest_hours: list[dict[str, Any]]
    most_expensive_hours: list[dict[str, Any]]
    # Tariff comparison fields
    fixed_tariff_unit_rate: float = 25.68  # Octopus 12M Fixed Sep 2025 v1
    fixed_tariff_standing_charge: float = 43.66  # p/day
    agile_standing_charge: float = 62.22  # p/day for Southampton
    days_in_period: int = 0
    fixed_total_cost_pence: float = 0.0
    agile_total_cost_pence: float = 0.0
    daily_comparison: list[dict[str, Any]] | None = None

    def to_dict(self) -> dict[str, Any]:
        return {
            "total_cost_pence": round(self.total_cost_pence, 2),
            "total_cost_pounds": round(self.total_cost_pence / 100, 2),
            "total_kwh": round(self.total_kwh, 3),
            "weighted_average_price": round(self.weighted_average_price, 2),
            "savings_vs_flat_rate": round(self.savings_vs_flat_rate, 2),
            "cost_by_period": self.cost_by_period,
            "cheapest_hours": self.cheapest_hours[:5],
            "most_expensive_hours": self.most_expensive_hours[:5],
            # Tariff comparison data
            "fixed_tariff_unit_rate": self.fixed_tariff_unit_rate,
            "fixed_tariff_standing_charge": self.fixed_tariff_standing_charge,
            "agile_standing_charge": self.agile_standing_charge,
            "days_in_period": self.days_in_period,
            "fixed_total_cost_pence": round(self.fixed_total_cost_pence, 2),
            "fixed_total_cost_pounds": round(self.fixed_total_cost_pence / 100, 2),
            "agile_total_cost_pence": round(self.agile_total_cost_pence, 2),
            "agile_total_cost_pounds": round(self.agile_total_cost_pence / 100, 2),
            "agile_savings_pence": round(self.fixed_total_cost_pence - self.agile_total_cost_pence, 2),
            "agile_savings_pounds": round((self.fixed_total_cost_pence - self.agile_total_cost_pence) / 100, 2),
            "daily_comparison": self.daily_comparison or [],
        }


def calculate_price_statistics(prices: list[dict[str, Any]]) -> PriceStatistics:
    """
    Calculate statistics for a list of price periods.

    Args:
        prices: List of price periods from the Octopus API

    Returns:
        PriceStatistics object with computed stats
    """
    if not prices:
        return PriceStatistics(
            count=0,
            average=0.0,
            minimum=0.0,
            maximum=0.0,
            negative_count=0,
            total_negative_value=0.0,
            cheapest_periods=[],
            most_expensive_periods=[],
        )

    values = [p["value_inc_vat"] for p in prices]

    # Find negative prices
    negative_prices = [p for p in prices if p["value_inc_vat"] < 0]

    # Sort for cheapest/most expensive
    sorted_by_price = sorted(prices, key=lambda x: x["value_inc_vat"])

    return PriceStatistics(
        count=len(prices),
        average=sum(values) / len(values),
        minimum=min(values),
        maximum=max(values),
        negative_count=len(negative_prices),
        total_negative_value=sum(p["value_inc_vat"] for p in negative_prices),
        cheapest_periods=sorted_by_price[:5],
        most_expensive_periods=list(reversed(sorted_by_price[-5:])),
    )


def calculate_consumption_statistics(
    consumption: list[dict[str, Any]],
) -> ConsumptionStatistics:
    """
    Calculate statistics for consumption data.

    Args:
        consumption: List of consumption periods from the Octopus API

    Returns:
        ConsumptionStatistics object with computed stats
    """
    if not consumption:
        return ConsumptionStatistics(
            total_kwh=0.0,
            period_count=0,
            average_per_period=0.0,
            peak_consumption=0.0,
            peak_period=None,
            daily_breakdown={},
        )

    # Calculate totals
    total_kwh = sum(c["consumption"] for c in consumption)

    # Find peak consumption
    peak_period = max(consumption, key=lambda x: x["consumption"])

    # Calculate daily breakdown
    daily_breakdown: dict[str, float] = {}
    for c in consumption:
        # Parse the interval start
        interval_start = c["interval_start"]
        if isinstance(interval_start, str):
            dt = datetime.fromisoformat(interval_start.replace("Z", "+00:00"))
        else:
            dt = interval_start

        date_key = dt.strftime("%Y-%m-%d")
        daily_breakdown[date_key] = daily_breakdown.get(date_key, 0) + c["consumption"]

    return ConsumptionStatistics(
        total_kwh=total_kwh,
        period_count=len(consumption),
        average_per_period=total_kwh / len(consumption),
        peak_consumption=peak_period["consumption"],
        peak_period=peak_period,
        daily_breakdown=daily_breakdown,
    )


def calculate_cost_analysis(
    prices: list[dict[str, Any]],
    consumption: list[dict[str, Any]],
    flat_rate_pence: float = 25.68,  # Octopus 12M Fixed September 2025 v1 rate
    fixed_standing_charge_pence: float = 43.66,  # Fixed tariff standing charge p/day
    agile_standing_charge_pence: float = 62.22,  # Agile standing charge p/day (Southampton)
) -> CostAnalysis:
    """
    Calculate cost analysis by matching consumption to prices.

    Args:
        prices: List of price periods
        consumption: List of consumption periods
        flat_rate_pence: Flat rate to compare against (default: Octopus 12M Fixed Sep 2025 v1)
        fixed_standing_charge_pence: Daily standing charge for fixed tariff (p/day)
        agile_standing_charge_pence: Daily standing charge for Agile tariff (p/day)

    Returns:
        CostAnalysis object with cost breakdown and tariff comparison
    """
    if not prices or not consumption:
        return CostAnalysis(
            total_cost_pence=0.0,
            total_kwh=0.0,
            weighted_average_price=0.0,
            savings_vs_flat_rate=0.0,
            cost_by_period=[],
            cheapest_hours=[],
            most_expensive_hours=[],
        )

    # Create a lookup for prices by period start
    price_lookup = {}
    for p in prices:
        valid_from = p["valid_from"]
        if isinstance(valid_from, str):
            # Normalize to just date and time for matching
            valid_from = valid_from[:16]  # Take first 16 chars (YYYY-MM-DDTHH:MM)
        price_lookup[valid_from] = p["value_inc_vat"]

    # Calculate cost for each consumption period
    cost_by_period = []
    total_cost = 0.0
    total_kwh = 0.0
    daily_costs: dict[str, dict[str, Any]] = {}  # Track costs by day

    for c in consumption:
        interval_start = c["interval_start"]
        if isinstance(interval_start, str):
            interval_key = interval_start[:16]
            dt = datetime.fromisoformat(interval_start.replace("Z", "+00:00"))
        else:
            interval_key = interval_start.strftime("%Y-%m-%dT%H:%M")
            dt = interval_start

        date_key = dt.strftime("%Y-%m-%d")
        kwh = c["consumption"]
        total_kwh += kwh

        # Initialize daily tracking
        if date_key not in daily_costs:
            daily_costs[date_key] = {
                "date": date_key,
                "kwh": 0.0,
                "agile_unit_cost": 0.0,
                "fixed_unit_cost": 0.0,
            }

        daily_costs[date_key]["kwh"] += kwh
        daily_costs[date_key]["fixed_unit_cost"] += kwh * flat_rate_pence

        # Find matching price
        price = price_lookup.get(interval_key)

        if price is not None:
            cost = kwh * price
            total_cost += cost
            daily_costs[date_key]["agile_unit_cost"] += cost

            cost_by_period.append(
                {
                    "interval_start": c["interval_start"],
                    "interval_end": c["interval_end"],
                    "consumption_kwh": kwh,
                    "price_pence": price,
                    "cost_pence": round(cost, 2),
                }
            )

    # Calculate weighted average price
    weighted_avg = total_cost / total_kwh if total_kwh > 0 else 0

    # Calculate savings vs flat rate (unit costs only, for backward compatibility)
    flat_rate_cost = total_kwh * flat_rate_pence
    savings = flat_rate_cost - total_cost

    # Calculate number of days in period
    days_in_period = len(daily_costs)

    # Calculate total costs including standing charges
    fixed_total = flat_rate_cost + (days_in_period * fixed_standing_charge_pence)
    agile_total = total_cost + (days_in_period * agile_standing_charge_pence)

    # Build daily comparison data
    daily_comparison = []
    for date_key in sorted(daily_costs.keys()):
        day_data = daily_costs[date_key]
        # Add standing charges to each day
        day_fixed_total = day_data["fixed_unit_cost"] + fixed_standing_charge_pence
        day_agile_total = day_data["agile_unit_cost"] + agile_standing_charge_pence
        day_savings = day_fixed_total - day_agile_total

        daily_comparison.append({
            "date": date_key,
            "kwh": round(day_data["kwh"], 3),
            "fixed_cost_pence": round(day_fixed_total, 2),
            "agile_cost_pence": round(day_agile_total, 2),
            "savings_pence": round(day_savings, 2),
            "agile_cheaper": day_savings > 0,
        })

    # Sort by cost per kWh (effective price paid)
    sorted_by_cost = sorted(
        cost_by_period,
        key=lambda x: x["price_pence"] if x["consumption_kwh"] > 0 else float("inf"),
    )

    return CostAnalysis(
        total_cost_pence=total_cost,
        total_kwh=total_kwh,
        weighted_average_price=weighted_avg,
        savings_vs_flat_rate=savings,
        cost_by_period=cost_by_period,
        cheapest_hours=sorted_by_cost[:5],
        most_expensive_hours=list(reversed(sorted_by_cost[-5:])),
        fixed_tariff_unit_rate=flat_rate_pence,
        fixed_tariff_standing_charge=fixed_standing_charge_pence,
        agile_standing_charge=agile_standing_charge_pence,
        days_in_period=days_in_period,
        fixed_total_cost_pence=fixed_total,
        agile_total_cost_pence=agile_total,
        daily_comparison=daily_comparison,
    )


def get_current_and_upcoming_prices(
    prices: list[dict[str, Any]], hours_ahead: int = 12
) -> dict[str, Any]:
    """
    Get current price and upcoming periods.

    Args:
        prices: List of price periods
        hours_ahead: How many hours ahead to include

    Returns:
        Dictionary with current price and upcoming periods
    """
    now = datetime.now(UTC)
    cutoff = now + timedelta(hours=hours_ahead)

    current_price = None
    upcoming = []
    past_24h = []

    for p in prices:
        valid_from = p["valid_from"]
        valid_to = p["valid_to"]

        if isinstance(valid_from, str):
            valid_from = datetime.fromisoformat(valid_from.replace("Z", "+00:00"))
        if isinstance(valid_to, str):
            valid_to = datetime.fromisoformat(valid_to.replace("Z", "+00:00"))

        # Current period
        if valid_from <= now < valid_to:
            current_price = p

        # Upcoming periods
        if valid_from >= now and valid_from < cutoff:
            upcoming.append(p)

        # Past 24 hours
        if valid_from >= now - timedelta(hours=24) and valid_from < now:
            past_24h.append(p)

    # Sort upcoming by time
    upcoming.sort(key=lambda x: x["valid_from"])

    # Find best upcoming times
    best_upcoming = (
        sorted(upcoming, key=lambda x: x["value_inc_vat"])[:5] if upcoming else []
    )

    return {
        "current": current_price,
        "upcoming": upcoming,
        "past_24h": past_24h,
        "best_upcoming": best_upcoming,
        "has_negative_upcoming": any(p["value_inc_vat"] < 0 for p in upcoming),
    }


def aggregate_by_hour(
    data: list[dict[str, Any]],
    value_key: str = "value_inc_vat",
    time_key: str = "valid_from",
) -> list[dict[str, Any]]:
    """
    Aggregate half-hourly data to hourly averages.

    Args:
        data: List of half-hourly periods
        value_key: Key containing the value to aggregate
        time_key: Key containing the timestamp

    Returns:
        List of hourly aggregated values
    """
    hourly_data: dict[str, list[float]] = {}

    for item in data:
        timestamp = item[time_key]
        if isinstance(timestamp, str):
            dt = datetime.fromisoformat(timestamp.replace("Z", "+00:00"))
        else:
            dt = timestamp

        hour_key = dt.strftime("%Y-%m-%dT%H:00:00Z")

        if hour_key not in hourly_data:
            hourly_data[hour_key] = []
        hourly_data[hour_key].append(item[value_key])

    result = []
    for hour, values in sorted(hourly_data.items()):
        result.append(
            {
                "timestamp": hour,
                "average": sum(values) / len(values),
                "min": min(values),
                "max": max(values),
                "count": len(values),
            }
        )

    return result
