"""Add missing columns: doctors.address_ru, users.refresh_token

Revision ID: 0002
Revises: 0001
Create Date: 2026-04-10

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0002"
down_revision: Union[str, None] = "0001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Добавляем address_ru в doctors
    op.add_column("doctors", sa.Column("address_ru", sa.String(512), nullable=True))

    # Добавляем refresh_token в users
    op.add_column("users", sa.Column("refresh_token", sa.String(128), nullable=True))
    op.create_unique_constraint("uq_users_refresh_token", "users", ["refresh_token"])
    op.create_index("ix_users_refresh_token", "users", ["refresh_token"])


def downgrade() -> None:
    op.drop_index("ix_users_refresh_token", table_name="users")
    op.drop_constraint("uq_users_refresh_token", "users", type_="unique")
    op.drop_column("users", "refresh_token")
    op.drop_column("doctors", "address_ru")
