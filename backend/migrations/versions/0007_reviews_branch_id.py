"""Add branch_id to reviews for pharmacy branch reviews

Revision ID: 0007
Revises: 0006
Create Date: 2026-04-27
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0007"
down_revision: Union[str, None] = "0006"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        "reviews",
        sa.Column("branch_id", sa.Integer(), sa.ForeignKey("pharmacy_branches.id"), nullable=True),
    )


def downgrade() -> None:
    op.drop_column("reviews", "branch_id")
