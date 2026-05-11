"""Add phone, education, consultation_language to doctors

Revision ID: 0006
Revises: 0005
Create Date: 2026-04-24
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0006"
down_revision: Union[str, None] = "0005"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    existing = [c["name"] for c in inspector.get_columns("doctors")]

    new_cols = {
        "phone":                sa.Column("phone",                sa.String(30),  nullable=True),
        "education":            sa.Column("education",            sa.Text,        nullable=True),
        "consultation_language":sa.Column("consultation_language",sa.String(100), nullable=True),
    }
    for col_name, col_def in new_cols.items():
        if col_name not in existing:
            op.add_column("doctors", col_def)


def downgrade() -> None:
    for col in ["phone", "education", "consultation_language"]:
        op.drop_column("doctors", col)
