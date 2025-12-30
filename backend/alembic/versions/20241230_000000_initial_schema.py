"""Initial schema for Octopus Agile Dashboard

Revision ID: 001
Revises:
Create Date: 2024-12-30 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision: str = '001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Create cached_prices table
    op.create_table(
        'cached_prices',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('region', sa.String(length=2), nullable=False),
        sa.Column('product_code', sa.String(length=50), nullable=False),
        sa.Column('valid_from', sa.DateTime(timezone=True), nullable=False),
        sa.Column('valid_to', sa.DateTime(timezone=True), nullable=False),
        sa.Column('value_exc_vat', sa.Float(), nullable=False),
        sa.Column('value_inc_vat', sa.Float(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('region', 'product_code', 'valid_from', name='uix_price_period')
    )
    op.create_index('ix_cached_prices_region', 'cached_prices', ['region'], unique=False)
    op.create_index('ix_prices_valid_from', 'cached_prices', ['valid_from'], unique=False)
    op.create_index('ix_prices_region_period', 'cached_prices', ['region', 'valid_from', 'valid_to'], unique=False)

    # Create cached_consumption table
    op.create_table(
        'cached_consumption',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('mpan', sa.String(length=13), nullable=False),
        sa.Column('serial_number', sa.String(length=20), nullable=False),
        sa.Column('interval_start', sa.DateTime(timezone=True), nullable=False),
        sa.Column('interval_end', sa.DateTime(timezone=True), nullable=False),
        sa.Column('consumption', sa.Float(), nullable=False),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('mpan', 'interval_start', name='uix_consumption_period')
    )
    op.create_index('ix_cached_consumption_mpan', 'cached_consumption', ['mpan'], unique=False)
    op.create_index('ix_consumption_interval', 'cached_consumption', ['interval_start'], unique=False)
    op.create_index('ix_consumption_mpan_interval', 'cached_consumption', ['mpan', 'interval_start', 'interval_end'], unique=False)

    # Create price_stats table
    op.create_table(
        'price_stats',
        sa.Column('id', sa.Integer(), autoincrement=True, nullable=False),
        sa.Column('region', sa.String(length=2), nullable=False),
        sa.Column('date', sa.DateTime(timezone=True), nullable=False),
        sa.Column('min_price', sa.Float(), nullable=False),
        sa.Column('max_price', sa.Float(), nullable=False),
        sa.Column('avg_price', sa.Float(), nullable=False),
        sa.Column('negative_periods', sa.Integer(), nullable=True),
        sa.Column('total_periods', sa.Integer(), nullable=False),
        sa.Column('stats_json', postgresql.JSONB(astext_type=sa.Text()), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id'),
        sa.UniqueConstraint('region', 'date', name='uix_daily_stats')
    )
    op.create_index('ix_stats_date', 'price_stats', ['date'], unique=False)


def downgrade() -> None:
    # Drop price_stats table
    op.drop_index('ix_stats_date', table_name='price_stats')
    op.drop_table('price_stats')

    # Drop cached_consumption table
    op.drop_index('ix_consumption_mpan_interval', table_name='cached_consumption')
    op.drop_index('ix_consumption_interval', table_name='cached_consumption')
    op.drop_index('ix_cached_consumption_mpan', table_name='cached_consumption')
    op.drop_table('cached_consumption')

    # Drop cached_prices table
    op.drop_index('ix_prices_region_period', table_name='cached_prices')
    op.drop_index('ix_prices_valid_from', table_name='cached_prices')
    op.drop_index('ix_cached_prices_region', table_name='cached_prices')
    op.drop_table('cached_prices')
