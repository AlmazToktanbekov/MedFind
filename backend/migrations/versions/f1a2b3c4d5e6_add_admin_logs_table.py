"""add admin_logs table

Revision ID: f1a2b3c4d5e6
Revises: dfc90d00f0e4
Create Date: 2026-05-17 10:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "f1a2b3c4d5e6"
down_revision: Union[str, None] = "3a57cba15610"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "admin_logs",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("admin_user_id", sa.Integer(), nullable=False),
        sa.Column("action", sa.String(length=60), nullable=False),
        sa.Column("target_type", sa.String(length=30), nullable=True),
        sa.Column("target_id", sa.Integer(), nullable=True),
        sa.Column("details", sa.Text(), nullable=True),
        sa.Column("ip_address", sa.String(length=64), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_admin_logs_admin_created", "admin_logs", ["admin_user_id", "created_at"])
    op.create_index("ix_admin_logs_target", "admin_logs", ["target_type", "target_id"])
    op.create_index("ix_admin_logs_action_created", "admin_logs", ["action", "created_at"])


def downgrade() -> None:
    op.drop_index("ix_admin_logs_action_created", table_name="admin_logs")
    op.drop_index("ix_admin_logs_target", table_name="admin_logs")
    op.drop_index("ix_admin_logs_admin_created", table_name="admin_logs")
    op.drop_table("admin_logs")
