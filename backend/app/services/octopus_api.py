"""
Octopus Energy API client for fetching prices and consumption data.
"""

import logging
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx

from app.core.cache import cache_manager
from app.core.config import settings

logger = logging.getLogger(__name__)


class OctopusAPIClient:
    """
    Client for interacting with the Octopus Energy API.
    Handles both public (prices) and authenticated (consumption) endpoints.
    """

    def __init__(self):
        self.base_url = settings.OCTOPUS_API_BASE_URL
        self.region = settings.REGION
        self.product_code = settings.PRODUCT_CODE
        self.api_key = settings.OCTOPUS_API_KEY
        self.mpan = settings.MPAN
        self.serial_number = settings.SERIAL_NUMBER

        # HTTP client timeout settings
        self.timeout = httpx.Timeout(30.0, connect=10.0)

    @property
    def tariff_code(self) -> str:
        """Generate the tariff code for the region."""
        return f"E-1R-{self.product_code}-{self.region}"

    async def fetch_prices(
        self,
        period_from: datetime | None = None,
        period_to: datetime | None = None,
        use_cache: bool = True,
    ) -> list[dict[str, Any]]:
        """
        Fetch Agile tariff prices.
        No authentication required for this endpoint.

        Args:
            period_from: Start of period (defaults to 24 hours ago)
            period_to: End of period (defaults to 24 hours from now)
            use_cache: Whether to use cached data if available

        Returns:
            List of price periods with values and timestamps
        """
        # Set default time range
        if period_from is None:
            period_from = datetime.now(UTC) - timedelta(hours=24)
        if period_to is None:
            period_to = datetime.now(UTC) + timedelta(hours=24)

        # Check cache first
        if use_cache:
            cache_key = cache_manager.generate_price_cache_key(period_from, period_to)
            cached = await cache_manager.get(cache_key)
            if cached:
                logger.debug(
                    f"Returning cached prices for {period_from} to {period_to}"
                )
                return cached

        # Build URL and parameters
        url = f"{self.base_url}/products/{self.product_code}/electricity-tariffs/{self.tariff_code}/standard-unit-rates/"
        params = {
            "period_from": period_from.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "period_to": period_to.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "page_size": 1500,  # Get all periods at once
        }

        logger.info(f"Fetching prices from {period_from} to {period_to}")

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()

            data = response.json()
            prices = data.get("results", [])

            # Sort by valid_from (oldest first)
            prices.sort(key=lambda x: x["valid_from"])

            logger.info(f"Retrieved {len(prices)} price periods")

            # Cache the results
            if use_cache and prices:
                cache_key = cache_manager.generate_price_cache_key(
                    period_from, period_to
                )
                await cache_manager.set(cache_key, prices)

            return prices

    async def fetch_current_prices(self) -> list[dict[str, Any]]:
        """Fetch prices for the current 48-hour window."""
        period_from = datetime.now(UTC) - timedelta(hours=24)
        period_to = datetime.now(UTC) + timedelta(hours=24)
        return await self.fetch_prices(period_from, period_to)

    async def fetch_consumption(
        self,
        period_from: datetime | None = None,
        period_to: datetime | None = None,
        use_cache: bool = True,
    ) -> list[dict[str, Any]]:
        """
        Fetch smart meter consumption data.
        Requires authentication with API key.

        Args:
            period_from: Start of period (defaults to 7 days ago)
            period_to: End of period (defaults to now)
            use_cache: Whether to use cached data if available

        Returns:
            List of consumption periods with kWh values
        """
        if not self.api_key or not self.mpan or not self.serial_number:
            raise ValueError(
                "OCTOPUS_API_KEY, MPAN, and SERIAL_NUMBER must be configured "
                "to fetch consumption data"
            )

        # Set default time range
        if period_from is None:
            period_from = datetime.now(UTC) - timedelta(days=7)
        if period_to is None:
            period_to = datetime.now(UTC)

        # Check cache first
        if use_cache:
            cache_key = cache_manager.generate_consumption_cache_key(
                period_from, period_to
            )
            cached = await cache_manager.get(cache_key)
            if cached:
                logger.debug(
                    f"Returning cached consumption for {period_from} to {period_to}"
                )
                return cached

        # Build URL and parameters
        url = f"{self.base_url}/electricity-meter-points/{self.mpan}/meters/{self.serial_number}/consumption/"
        params = {
            "period_from": period_from.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "period_to": period_to.strftime("%Y-%m-%dT%H:%M:%SZ"),
            "page_size": 25000,  # Get all periods at once
            "order_by": "period",
        }

        logger.info(f"Fetching consumption from {period_from} to {period_to}")

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(
                url,
                params=params,
                auth=(self.api_key, ""),  # HTTP Basic Auth, empty password
            )
            response.raise_for_status()

            data = response.json()
            consumption = data.get("results", [])

            # Sort by interval_start (oldest first)
            consumption.sort(key=lambda x: x["interval_start"])

            logger.info(f"Retrieved {len(consumption)} consumption periods")

            # Cache the results
            if use_cache and consumption:
                cache_key = cache_manager.generate_consumption_cache_key(
                    period_from, period_to
                )
                await cache_manager.set(cache_key, consumption)

            return consumption

    async def fetch_products(self) -> list[dict[str, Any]]:
        """
        Fetch available Agile products.
        Useful for detecting the current product code.
        """
        url = f"{self.base_url}/products/"
        params = {
            "is_variable": "true",
            "is_green": "true",
            "is_tracker": "false",
        }

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.get(url, params=params)
            response.raise_for_status()

            data = response.json()
            products = data.get("results", [])

            # Filter to Agile products only
            agile_products = [p for p in products if "AGILE" in p.get("code", "")]

            return agile_products

    async def get_current_product_code(self) -> str | None:
        """Get the latest Agile product code."""
        products = await self.fetch_products()
        if products:
            # Return the first (most recent) Agile product
            return products[0].get("code")
        return None


# Create a singleton instance
octopus_client = OctopusAPIClient()
