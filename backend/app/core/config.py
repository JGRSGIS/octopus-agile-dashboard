"""
Configuration management using Pydantic settings.
Loads from environment variables and .env file.
"""

from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


def find_env_file() -> Path | None:
    """Find .env file in current directory or parent directories."""
    current = Path.cwd()
    # Check current directory first (backend/)
    if (current / ".env").exists():
        return current / ".env"
    # Check parent directory (project root)
    if (current.parent / ".env").exists():
        return current.parent / ".env"
    # Check if we're in project root
    if (current / "backend" / "app").exists() and (current / ".env").exists():
        return current / ".env"
    return None


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Octopus Energy API Configuration
    OCTOPUS_API_KEY: str = Field(default="", description="Octopus Energy API key")
    MPAN: str = Field(default="", description="Meter Point Administration Number")
    SERIAL_NUMBER: str = Field(default="", description="Meter serial number")

    # Region Configuration
    REGION: str = Field(
        default="H", description="DNO region code (H = Southern England)"
    )

    # Product Configuration (auto-detected if not set)
    PRODUCT_CODE: str = Field(
        default="AGILE-24-10-01", description="Agile product code"
    )

    # Database Configuration
    DATABASE_URL: str = Field(
        default="postgresql+asyncpg://octopus:octopus@localhost:5432/octopus_agile",
        description="PostgreSQL connection string",
    )

    # Redis Configuration (optional)
    REDIS_URL: str | None = Field(default=None, description="Redis connection URL")

    # Cache Settings
    CACHE_ENABLED: bool = Field(default=True, description="Enable caching")
    CACHE_TTL_SECONDS: int = Field(default=3600, description="Cache TTL in seconds")
    PRICE_FETCH_INTERVAL_MINUTES: int = Field(
        default=30, description="Price fetch interval"
    )

    # Server Configuration
    API_HOST: str = Field(default="0.0.0.0", description="API host")
    API_PORT: int = Field(default=8000, description="API port")
    DEBUG: bool = Field(default=False, description="Debug mode")

    # CORS Settings
    CORS_ORIGINS: list[str] = Field(
        default=[
            "http://localhost:3000",
            "http://localhost:5173",
            "http://raspberrypi.local",
        ],
        description="Allowed CORS origins",
    )

    # Octopus API Base URL
    OCTOPUS_API_BASE_URL: str = Field(
        default="https://api.octopus.energy/v1",
        description="Octopus Energy API base URL",
    )

    @property
    def tariff_code(self) -> str:
        """Generate the full tariff code."""
        return f"E-1R-{self.PRODUCT_CODE}-{self.REGION}"

    @property
    def consumption_url(self) -> str:
        """Generate the consumption API URL."""
        return f"{self.OCTOPUS_API_BASE_URL}/electricity-meter-points/{self.MPAN}/meters/{self.SERIAL_NUMBER}/consumption/"

    @property
    def prices_url(self) -> str:
        """Generate the prices API URL."""
        return f"{self.OCTOPUS_API_BASE_URL}/products/{self.PRODUCT_CODE}/electricity-tariffs/{self.tariff_code}/standard-unit-rates/"

    # Use SettingsConfigDict for pydantic-settings v2
    model_config = SettingsConfigDict(
        env_file=find_env_file(),
        env_file_encoding="utf-8",
        case_sensitive=True,
        extra="ignore",  # Allow extra fields like VITE_API_URL from shared .env
    )


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings(_env_file=find_env_file())


settings = get_settings()
