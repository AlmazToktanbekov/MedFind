"""merge heads

Revision ID: 0519ddb41b41
Revises: 0010_notifications, 5a381110be93
Create Date: 2026-05-11 18:57:33.674949

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '0519ddb41b41'
down_revision: Union[str, None] = ('0010_notifications', '5a381110be93')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
