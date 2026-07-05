"""make_password_hash_nullable

Google sign-in users have no local password, so users.password_hash
must allow NULL.

Revision ID: a1b2c3d4e5f6
Revises: 872fcc238712
Create Date: 2026-07-05 00:00:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'a1b2c3d4e5f6'
down_revision: Union[str, Sequence[str], None] = '872fcc238712'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.alter_column('users', 'password_hash',
                    existing_type=sa.String(length=255),
                    nullable=True)


def downgrade() -> None:
    """Downgrade schema."""
    op.alter_column('users', 'password_hash',
                    existing_type=sa.String(length=255),
                    nullable=False)
