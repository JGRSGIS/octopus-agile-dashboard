"""
Octopus Energy GraphQL API client for real-time telemetry data.
Provides access to Home Mini device data via the smartMeterTelemetry query.
"""

import asyncio
import logging
from datetime import UTC, datetime, timedelta
from typing import Any

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)


class OctopusGraphQLClient:
    """
    Client for interacting with the Octopus Energy GraphQL API.
    Handles authentication, token refresh, and real-time telemetry queries.
    """

    GRAPHQL_URL = "https://api.octopus.energy/v1/graphql/"
    TOKEN_VALIDITY_MINUTES = 55  # Refresh before 60-minute expiry

    def __init__(self):
        self.api_key = settings.OCTOPUS_API_KEY
        self.account_number = settings.OCTOPUS_ACCOUNT_NUMBER
        self._token: str | None = None
        self._token_expires: datetime | None = None
        self._device_id: str | None = None
        self._lock = asyncio.Lock()
        self.timeout = httpx.Timeout(30.0, connect=10.0)

    async def _execute_query(
        self,
        query: str,
        variables: dict[str, Any] | None = None,
        use_auth: bool = True,
    ) -> dict[str, Any]:
        """Execute a GraphQL query/mutation."""
        headers = {"Content-Type": "application/json"}

        if use_auth:
            token = await self.get_token()
            if token:
                headers["Authorization"] = token

        payload: dict[str, Any] = {"query": query}
        if variables:
            payload["variables"] = variables

        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                self.GRAPHQL_URL,
                json=payload,
                headers=headers,
            )
            response.raise_for_status()
            result = response.json()

            if "errors" in result:
                error_msg = result["errors"][0].get("message", "GraphQL error")
                logger.error(f"GraphQL error: {error_msg}")
                raise ValueError(f"GraphQL error: {error_msg}")

            return result.get("data", {})

    async def get_token(self) -> str | None:
        """
        Get a valid authentication token, refreshing if necessary.
        Uses the API key to obtain a Kraken token.
        """
        async with self._lock:
            # Check if we have a valid token
            if self._token and self._token_expires:
                if datetime.now(UTC) < self._token_expires:
                    return self._token

            # Need to refresh token
            if not self.api_key:
                logger.warning("No API key configured for GraphQL authentication")
                return None

            query = """
            mutation ObtainKrakenToken($input: ObtainJSONWebTokenInput!) {
                obtainKrakenToken(input: $input) {
                    token
                }
            }
            """
            variables = {"input": {"APIKey": self.api_key}}

            try:
                logger.info("Obtaining new Kraken authentication token")
                result = await self._execute_query(query, variables, use_auth=False)
                self._token = result.get("obtainKrakenToken", {}).get("token")

                if self._token:
                    self._token_expires = datetime.now(UTC) + timedelta(
                        minutes=self.TOKEN_VALIDITY_MINUTES
                    )
                    logger.info("Successfully obtained Kraken token")
                else:
                    logger.error("Failed to obtain Kraken token")

                return self._token

            except Exception as e:
                logger.error(f"Error obtaining Kraken token: {e}")
                self._token = None
                self._token_expires = None
                return None

    async def get_device_id(self) -> str | None:
        """
        Get the Home Mini device ID from the account.
        Caches the result for subsequent calls.
        """
        if self._device_id:
            return self._device_id

        if not self.account_number:
            logger.warning("No account number configured for device discovery")
            return None

        query = """
        query GetDeviceId($accountNumber: String!) {
            account(accountNumber: $accountNumber) {
                electricityAgreements(active: true) {
                    meterPoint {
                        meters(includeInactive: false) {
                            smartDevices {
                                deviceId
                            }
                        }
                    }
                }
            }
        }
        """
        variables = {"accountNumber": self.account_number}

        try:
            logger.info(f"Fetching device ID for account {self.account_number}")
            result = await self._execute_query(query, variables)

            account = result.get("account", {})
            agreements = account.get("electricityAgreements", [])

            for agreement in agreements:
                meter_point = agreement.get("meterPoint", {})
                meters = meter_point.get("meters", [])
                for meter in meters:
                    smart_devices = meter.get("smartDevices", [])
                    for device in smart_devices:
                        device_id = device.get("deviceId")
                        if device_id:
                            self._device_id = device_id
                            logger.info(f"Found Home Mini device ID: {device_id}")
                            return device_id

            logger.warning("No Home Mini device found for account")
            return None

        except Exception as e:
            logger.error(f"Error fetching device ID: {e}")
            return None

    async def get_telemetry(
        self,
        start: datetime | None = None,
        end: datetime | None = None,
        grouping: str = "TEN_SECONDS",
    ) -> list[dict[str, Any]]:
        """
        Fetch real-time telemetry data from the Home Mini device.

        Args:
            start: Start time (defaults to 5 minutes ago)
            end: End time (defaults to now)
            grouping: Grouping interval (TEN_SECONDS, HALF_HOUR, etc.)

        Returns:
            List of telemetry readings with consumptionDelta, demand, etc.
        """
        device_id = await self.get_device_id()
        if not device_id:
            raise ValueError("No Home Mini device ID available")

        # Default time range: last 5 minutes
        if start is None:
            start = datetime.now(UTC) - timedelta(minutes=5)
        if end is None:
            end = datetime.now(UTC)

        query = """
        query SmartMeterTelemetry(
            $deviceId: String!
            $start: DateTime!
            $end: DateTime!
            $grouping: TelemetryGrouping
        ) {
            smartMeterTelemetry(
                deviceId: $deviceId
                start: $start
                end: $end
                grouping: $grouping
            ) {
                readAt
                consumptionDelta
                demand
                costDelta
                consumption
            }
        }
        """
        variables = {
            "deviceId": device_id,
            "start": start.isoformat(),
            "end": end.isoformat(),
            "grouping": grouping,
        }

        try:
            logger.debug(f"Fetching telemetry from {start} to {end}")
            result = await self._execute_query(query, variables)
            telemetry = result.get("smartMeterTelemetry", [])

            # Filter out None entries and sort by readAt
            telemetry = [t for t in telemetry if t is not None]
            telemetry.sort(key=lambda x: x.get("readAt", ""))

            logger.debug(f"Retrieved {len(telemetry)} telemetry readings")
            return telemetry

        except Exception as e:
            logger.error(f"Error fetching telemetry: {e}")
            raise

    async def get_latest_reading(self) -> dict[str, Any] | None:
        """
        Get the most recent telemetry reading.
        Fetches the last minute of data and returns the latest entry.
        """
        try:
            telemetry = await self.get_telemetry(
                start=datetime.now(UTC) - timedelta(minutes=1),
                end=datetime.now(UTC),
                grouping="TEN_SECONDS",
            )

            if telemetry:
                return telemetry[-1]
            return None

        except Exception as e:
            logger.error(f"Error fetching latest reading: {e}")
            return None

    async def check_home_mini_available(self) -> bool:
        """Check if Home Mini device is available and configured."""
        try:
            device_id = await self.get_device_id()
            return device_id is not None
        except Exception:
            return False


# Create a singleton instance
graphql_client = OctopusGraphQLClient()
