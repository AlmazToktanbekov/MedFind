"""Add whatsapp, telegram, instagram, email, logo_url to clinics

Revision ID: 0005
Revises: 0004
Create Date: 2026-04-24
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0005"
down_revision: Union[str, None] = "0004"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    existing = [c["name"] for c in inspector.get_columns("clinics")]

    new_cols = {
        "whatsapp":  sa.Column("whatsapp",  sa.String(30),  nullable=True),
        "telegram":  sa.Column("telegram",  sa.String(100), nullable=True),
        "instagram": sa.Column("instagram", sa.String(100), nullable=True),
        "email":     sa.Column("email",     sa.String(255), nullable=True),
        "logo_url":  sa.Column("logo_url",  sa.String(512), nullable=True),
    }
    for col_name, col_def in new_cols.items():
        if col_name not in existing:
            op.add_column("clinics", col_def)


def downgrade() -> None:
    for col in ["whatsapp", "telegram", "instagram", "email", "logo_url"]:
        op.drop_column("clinics", col)
