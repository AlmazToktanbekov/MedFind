"""Refactor pharmacy: replace pharmacies table with pharmacy_companies + pharmacy_branches + pharmacy_branch_photos

Revision ID: 0004
Revises: 0003
Create Date: 2026-04-24
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0004"
down_revision: Union[str, None] = "0003"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Удаляем старую таблицу pharmacies
    op.drop_table("pharmacies")

    # Создаём pharmacy_companies
    op.create_table(
        "pharmacy_companies",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, nullable=True),
        sa.Column("name", sa.String(255), nullable=False),
        sa.Column("logo_url", sa.String(512), nullable=True),
        sa.Column("main_phone", sa.String(30), nullable=True),
        sa.Column("website", sa.String(255), nullable=True),
        sa.Column("description", sa.Text, nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    # Создаём pharmacy_branches
    op.create_table(
        "pharmacy_branches",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("company_id", sa.Integer, sa.ForeignKey("pharmacy_companies.id"), nullable=False),
        sa.Column("address", sa.String(512), nullable=True),
        sa.Column("latitude", sa.Float, nullable=True),
        sa.Column("longitude", sa.Float, nullable=True),
        sa.Column("phone", sa.String(30), nullable=True),
        sa.Column("working_hours", sa.String(255), nullable=True),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("rating", sa.Float, nullable=False, server_default="0.0"),
        sa.Column("reviews_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )

    # Создаём pharmacy_branch_photos
    op.create_table(
        "pharmacy_branch_photos",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("branch_id", sa.Integer, sa.ForeignKey("pharmacy_branches.id"), nullable=False),
        sa.Column("url", sa.String(512), nullable=False),
        sa.Column("order", sa.Integer, nullable=False, server_default="0"),
    )


def downgrade() -> None:
    op.drop_table("pharmacy_branch_photos")
    op.drop_table("pharmacy_branches")
    op.drop_table("pharmacy_companies")

    op.create_table(
        "pharmacies",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, nullable=True),
        sa.Column("name_ru", sa.String(255), nullable=False),
        sa.Column("name_kg", sa.String(255), nullable=True),
        sa.Column("name_en", sa.String(255), nullable=True),
        sa.Column("address_ru", sa.String(512), nullable=True),
        sa.Column("address_kg", sa.String(512), nullable=True),
        sa.Column("address_en", sa.String(512), nullable=True),
        sa.Column("phone", sa.String(30), nullable=True),
        sa.Column("photo_url", sa.String(512), nullable=True),
        sa.Column("latitude", sa.Float, nullable=True),
        sa.Column("longitude", sa.Float, nullable=True),
        sa.Column("is_open_24h", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("working_hours_ru", sa.String(255), nullable=True),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
