"""add complaints table

Revision ID: c4d5e6f7a8b9
Revises: f1a2b3c4d5e6
Create Date: 2026-05-17 12:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = "c4d5e6f7a8b9"
down_revision: Union[str, None] = "f1a2b3c4d5e6"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "complaints",
        sa.Column("id", sa.Integer(), nullable=False),
        sa.Column("author_id", sa.Integer(), nullable=False),
        sa.Column("target_type", sa.String(length=30), nullable=False),
        sa.Column("target_id", sa.Integer(), nullable=False),
        sa.Column("reason", sa.String(length=40), nullable=False),
        sa.Column("comment", sa.Text(), nullable=True),
        sa.Column("status", sa.String(length=20), nullable=False, server_default="new"),
        sa.Column("resolution_note", sa.Text(), nullable=True),
        sa.Column("resolved_by_admin_id", sa.Integer(), nullable=True),
        sa.Column("resolved_at", sa.DateTime(timezone=True), nullable=True),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.ForeignKeyConstraint(["author_id"], ["users.id"]),
        sa.PrimaryKeyConstraint("id"),
    )
    op.create_index("ix_complaints_target", "complaints", ["target_type", "target_id"])
    op.create_index("ix_complaints_status_created", "complaints", ["status", "created_at"])
    op.create_index(
        "ix_complaints_target_created",
        "complaints",
        ["target_type", "target_id", "created_at"],
    )


def downgrade() -> None:
    op.drop_index("ix_complaints_target_created", table_name="complaints")
    op.drop_index("ix_complaints_status_created", table_name="complaints")
    op.drop_index("ix_complaints_target", table_name="complaints")
    op.drop_table("complaints")
