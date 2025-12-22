"""
SQLAlchemy database models for caching price and consumption data.
"""

from datetime import datetime
from sqlalchemy import Column, Integer, Float, String, DateTime, Index, UniqueConstraint
from sqlalchemy.dialects.postgresql import JSONB
from app.db.database import Base


class CachedPrice(Base):
    """Cached Agile tariff price data."""
    
    __tablename__ = "cached_prices"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    region = Column(String(2), nullable=False, index=True)
    product_code = Column(String(50), nullable=False)
    valid_from = Column(DateTime(timezone=True), nullable=False)
    valid_to = Column(DateTime(timezone=True), nullable=False)
    value_exc_vat = Column(Float, nullable=False)
    value_inc_vat = Column(Float, nullable=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    
    __table_args__ = (
        UniqueConstraint('region', 'product_code', 'valid_from', name='uix_price_period'),
        Index('ix_prices_valid_from', 'valid_from'),
        Index('ix_prices_region_period', 'region', 'valid_from', 'valid_to'),
    )
    
    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return {
            "valid_from": self.valid_from.isoformat() if self.valid_from else None,
            "valid_to": self.valid_to.isoformat() if self.valid_to else None,
            "value_exc_vat": self.value_exc_vat,
            "value_inc_vat": self.value_inc_vat,
        }


class CachedConsumption(Base):
    """Cached smart meter consumption data."""
    
    __tablename__ = "cached_consumption"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    mpan = Column(String(13), nullable=False, index=True)
    serial_number = Column(String(20), nullable=False)
    interval_start = Column(DateTime(timezone=True), nullable=False)
    interval_end = Column(DateTime(timezone=True), nullable=False)
    consumption = Column(Float, nullable=False)  # kWh
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    
    __table_args__ = (
        UniqueConstraint('mpan', 'interval_start', name='uix_consumption_period'),
        Index('ix_consumption_interval', 'interval_start'),
        Index('ix_consumption_mpan_interval', 'mpan', 'interval_start', 'interval_end'),
    )
    
    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return {
            "interval_start": self.interval_start.isoformat() if self.interval_start else None,
            "interval_end": self.interval_end.isoformat() if self.interval_end else None,
            "consumption": self.consumption,
        }


class PriceStats(Base):
    """Daily price statistics for quick access."""
    
    __tablename__ = "price_stats"
    
    id = Column(Integer, primary_key=True, autoincrement=True)
    region = Column(String(2), nullable=False)
    date = Column(DateTime(timezone=True), nullable=False)
    min_price = Column(Float, nullable=False)
    max_price = Column(Float, nullable=False)
    avg_price = Column(Float, nullable=False)
    negative_periods = Column(Integer, default=0)
    total_periods = Column(Integer, nullable=False)
    stats_json = Column(JSONB, nullable=True)  # Additional statistics
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    
    __table_args__ = (
        UniqueConstraint('region', 'date', name='uix_daily_stats'),
        Index('ix_stats_date', 'date'),
    )
    
    def to_dict(self) -> dict:
        """Convert to dictionary."""
        return {
            "date": self.date.isoformat() if self.date else None,
            "min_price": self.min_price,
            "max_price": self.max_price,
            "avg_price": self.avg_price,
            "negative_periods": self.negative_periods,
            "total_periods": self.total_periods,
            "stats": self.stats_json,
        }
