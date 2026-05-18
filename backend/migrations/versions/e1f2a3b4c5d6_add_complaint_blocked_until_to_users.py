"""add complaint_blocked_until to users

Revision ID: e1f2a3b4c5d6
Revises: d5e6f7a8b9c0
Create Date: 2026-05-18
"""
from alembic import op
import sqlalchemy as sa

revision = 'e1f2a3b4c5d6'
down_revision = 'd5e6f7a8b9c0'
branch_labels = None
depends_on = None


def upgrade():
    op.add_column(
        'users',
        sa.Column('complaint_blocked_until', sa.DateTime(timezone=True), nullable=True),
    )


def downgrade():
    op.drop_column('users', 'complaint_blocked_until')
