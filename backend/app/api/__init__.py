"""API routers for prices, consumption, and analysis."""

from app.api.analysis import router as analysis_router
from app.api.consumption import router as consumption_router
from app.api.prices import router as prices_router

__all__ = ["analysis_router", "consumption_router", "prices_router"]
