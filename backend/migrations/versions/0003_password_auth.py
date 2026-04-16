"""Switch to password-based auth: drop otp_codes, add password_hash to users

Revision ID: 0003
Revises: 0002
Create Date: 2026-04-10
"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0003"
down_revision: Union[str, None] = "0002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Удаляем таблицу OTP (больше не нужна)
    op.drop_table("otp_codes")

    # Добавляем password_hash в users (если ещё нет)
    conn = op.get_bind()
    inspector = sa.inspect(conn)
    cols = [c["name"] for c in inspector.get_columns("users")]
    if "password_hash" not in cols:
        op.add_column(
            "users",
            sa.Column("password_hash", sa.String(255), nullable=True),
        )

    # Добавляем photo_url в pharmacies (если ещё нет)
    pharm_cols = [c["name"] for c in inspector.get_columns("pharmacies")]
    if "photo_url" not in pharm_cols:
        op.add_column(
            "pharmacies",
            sa.Column("photo_url", sa.String(512), nullable=True),
        )


def downgrade() -> None:
    op.create_table(
        "otp_codes",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("phone", sa.String(20), nullable=False, index=True),
        sa.Column("code", sa.String(10), nullable=False),
        sa.Column("is_used", sa.Boolean, nullable=False, default=False),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
    )
