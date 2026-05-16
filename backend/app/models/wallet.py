from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import String, DateTime, Integer, Numeric, ForeignKey, Index, UniqueConstraint, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from decimal import Decimal
from app.core.database import Base


class Wallet(Base):
    """Личный счёт клиники или аптеки. Хранит баланс в USD (Decimal для точности денег)."""
    __tablename__ = "wallets"
    __table_args__ = (
        UniqueConstraint("owner_type", "owner_id", name="uq_wallet_owner"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    owner_type: Mapped[str] = mapped_column(String(20))  # "clinic" | "pharmacy"
    owner_id: Mapped[int] = mapped_column(Integer)

    balance_usd: Mapped[Decimal] = mapped_column(
        Numeric(12, 2), default=Decimal("0.00")
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )


class WalletTransaction(Base):
    """История операций по счёту: пополнения (с заявкой и кодом), списания за подписку, возвраты."""
    __tablename__ = "wallet_transactions"
    __table_args__ = (
        Index("ix_wallet_tx_wallet_created", "wallet_id", "created_at"),
        Index("ix_wallet_tx_status", "status"),
        Index("ix_wallet_tx_payment_code", "payment_code"),
    )

    id: Mapped[int] = mapped_column(primary_key=True)
    wallet_id: Mapped[int] = mapped_column(ForeignKey("wallets.id", ondelete="CASCADE"))

    type: Mapped[str] = mapped_column(String(20))
    # "topup" | "purchase" | "refund" | "credit"

    amount_usd: Mapped[Decimal] = mapped_column(Numeric(12, 2))
    # Положительное число всегда; знак подразумевается из type:
    #   topup, credit, refund → плюс к балансу
    #   purchase → минус с баланса

    balance_after_usd: Mapped[Optional[Decimal]] = mapped_column(Numeric(12, 2))
    # Снимок баланса после операции (для success). null пока pending.

    status: Mapped[str] = mapped_column(String(20), default="pending")
    # "pending" (заявка на пополнение, ждёт админа) | "success" | "cancelled"

    payment_code: Mapped[Optional[str]] = mapped_column(String(32))
    # Для type=topup: уникальный код вида MEDF-31-A7K4

    related_subscription_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("subscriptions.id", ondelete="SET NULL")
    )
    # Для type=purchase: подписка, созданная этим списанием

    comment: Mapped[Optional[str]] = mapped_column(Text)
    # Свободный текст: для topup — от клиники, для cancelled — причина от админа

    admin_user_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("users.id", ondelete="SET NULL")
    )
    # Кто подтвердил/отклонил (для аудита)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))

    wallet: Mapped[Wallet] = relationship(lazy="noload")
