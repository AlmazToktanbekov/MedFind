"""add security fields: user lockout + otp attempts

Revision ID: c8a1f7d3b2e9
Revises: 87dc94deaa00
Create Date: 2026-05-14 16:50:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


revision: str = 'c8a1f7d3b2e9'
down_revision: Union[str, None] = '87dc94deaa00'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column(
        'users',
        sa.Column('failed_login_attempts', sa.Integer(), nullable=False, server_default='0'),
    )
    op.add_column(
        'users',
        sa.Column('locked_until', sa.DateTime(timezone=True), nullable=True),
    )
    op.add_column(
        'otp_codes',
        sa.Column('attempts', sa.Integer(), nullable=False, server_default='0'),
    )


def downgrade() -> None:
    op.drop_column('otp_codes', 'attempts')
    op.drop_column('users', 'locked_until')
    op.drop_column('users', 'failed_login_attempts')
