"""admin panel phase A: user fields, clinic/pharmacy frozen, search_logs, broadcasts

Revision ID: d5e6f7a8b9c0
Revises: c4d5e6f7a8b9
Create Date: 2026-05-17 14:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "d5e6f7a8b9c0"
down_revision: Union[str, None] = "c4d5e6f7a8b9"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ── users: новые поля для админки ──
    op.add_column("users", sa.Column("last_active_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("users", sa.Column("must_change_password", sa.Boolean(), nullable=False, server_default="false"))
    op.add_column("users", sa.Column("deleted_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("users", sa.Column("city", sa.String(length=100), nullable=True))
    op.create_index("ix_users_last_active_at", "users", ["last_active_at"])
    op.create_index("ix_users_city", "users", ["city"])

    # ── clinics: заморозка ──
    op.add_column("clinics", sa.Column("is_frozen", sa.Boolean(), nullable=False, server_default="false"))
    op.add_column("clinics", sa.Column("frozen_reason", sa.Text(), nullable=True))

    # ── pharmacy_companies: заморозка ──
    op.add_column("pharmacy_companies", sa.Column("is_frozen", sa.Boolean(), nullable=False, server_default="false"))
    op.add_column("pharmacy_companies", sa.Column("frozen_reason", sa.Text(), nullable=True))

    # ── search_logs ──
    op.create_table(
        "search_logs",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=True),
        sa.Column("query", sa.String(length=255), nullable=False),
        sa.Column("results_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_search_logs_query", "search_logs", ["query"])
    op.create_index("ix_search_logs_created", "search_logs", ["created_at"])

    # ── broadcasts ──
    op.create_table(
        "broadcasts",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("title", sa.String(length=200), nullable=False),
        sa.Column("body", sa.Text(), nullable=False),
        sa.Column("image_url", sa.String(length=512), nullable=True),
        sa.Column("segment", sa.JSON(), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="draft"),
        sa.Column("scheduled_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("sent_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("failed_count", sa.Integer(), nullable=False, server_default="0"),
        sa.Column("created_by_admin_id", sa.Integer(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_broadcasts_status_scheduled", "broadcasts", ["status", "scheduled_at"])

    op.create_table(
        "broadcast_deliveries",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("broadcast_id", sa.Integer(), nullable=False),
        sa.Column("user_id", sa.Integer(), nullable=False),
        sa.Column("status", sa.String(length=20), nullable=False),
        sa.Column("error", sa.Text(), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["broadcast_id"], ["broadcasts.id"], ondelete="CASCADE"),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_bd_broadcast_status", "broadcast_deliveries", ["broadcast_id", "status"])


def downgrade() -> None:
    op.drop_index("ix_bd_broadcast_status", table_name="broadcast_deliveries")
    op.drop_table("broadcast_deliveries")
    op.drop_index("ix_broadcasts_status_scheduled", table_name="broadcasts")
    op.drop_table("broadcasts")
    op.drop_index("ix_search_logs_created", table_name="search_logs")
    op.drop_index("ix_search_logs_query", table_name="search_logs")
    op.drop_table("search_logs")
    op.drop_column("pharmacy_companies", "frozen_reason")
    op.drop_column("pharmacy_companies", "is_frozen")
    op.drop_column("clinics", "frozen_reason")
    op.drop_column("clinics", "is_frozen")
    op.drop_index("ix_users_city", table_name="users")
    op.drop_index("ix_users_last_active_at", table_name="users")
    op.drop_column("users", "city")
    op.drop_column("users", "deleted_at")
    op.drop_column("users", "must_change_password")
    op.drop_column("users", "last_active_at")
