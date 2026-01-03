"""
Octopus Agile Dashboard - FastAPI Backend
Main application entry point
"""

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api import analysis, consumption, live, prices
from app.core.cache import cache_manager
from app.core.config import settings
from app.db.database import Base, engine

# Configure logging
logging.basicConfig(
    level=logging.INFO if not settings.DEBUG else logging.DEBUG,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler for startup and shutdown events."""
    # Startup
    logger.info("Starting Octopus Agile Dashboard API...")

    # Initialize database tables
    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    logger.info("Database tables initialized")

    # Initialize cache
    await cache_manager.initialize()
    logger.info("Cache manager initialized")

    # Pre-fetch current prices on startup
    try:
        from app.services.octopus_api import OctopusAPIClient

        client = OctopusAPIClient()
        await client.fetch_current_prices()
        logger.info("Initial price data fetched successfully")
    except Exception as e:
        logger.warning(f"Could not fetch initial prices: {e}")

    yield

    # Shutdown
    logger.info("Shutting down Octopus Agile Dashboard API...")
    await cache_manager.close()


# Create FastAPI application
app = FastAPI(
    title="Octopus Agile Dashboard API",
    description="API for Octopus Energy Agile tariff prices and smart meter consumption",
    version="1.0.0",
    lifespan=lifespan,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
    openapi_url="/api/openapi.json",
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(prices.router, prefix="/api/prices", tags=["Prices"])
app.include_router(consumption.router, prefix="/api/consumption", tags=["Consumption"])
app.include_router(analysis.router, prefix="/api/analysis", tags=["Analysis"])
app.include_router(live.router, prefix="/api/live", tags=["Live"])


@app.get("/api/health")
async def health_check():
    """Health check endpoint."""
    # Check Home Mini availability
    home_mini_available = False
    try:
        from app.services.octopus_graphql import graphql_client

        home_mini_available = await graphql_client.check_home_mini_available()
    except Exception:
        pass

    return {
        "status": "healthy",
        "version": "1.0.0",
        "region": settings.REGION,
        "cache_enabled": settings.CACHE_ENABLED,
        "home_mini_available": home_mini_available,
    }


@app.get("/api")
async def root():
    """API root endpoint with documentation links."""
    return {
        "message": "Octopus Agile Dashboard API",
        "documentation": "/api/docs",
        "health": "/api/health",
        "endpoints": {
            "prices": "/api/prices",
            "consumption": "/api/consumption",
            "analysis": "/api/analysis",
            "live": "/api/live",
        },
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.API_HOST,
        port=settings.API_PORT,
        reload=settings.DEBUG,
    )
