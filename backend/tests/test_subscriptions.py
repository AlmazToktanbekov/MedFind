"""Тесты подписок: триал, лимиты, переходы между планами."""
from datetime import datetime, timezone, timedelta

import pytest

from app.services import subscription_service as subs


async def test_start_trial_creates_pro_subscription(db, make_clinic):
    """При создании клиники триал даёт Pro на 30 дней."""
    clinic = await make_clinic()

    sub = await subs.start_trial(db, "clinic", clinic.id)

    assert sub is not None
    assert sub.plan == "pro"
    assert sub.is_trial is True
    assert sub.status == "active"
    assert sub.expires_at is not None
    days_left = (sub.expires_at - datetime.now(timezone.utc)).days
    assert 29 <= days_left <= 30


async def test_trial_can_be_used_only_once(db, make_clinic):
    """Повторный вызов start_trial возвращает None и не создаёт подписку."""
    clinic = await make_clinic()
    first = await subs.start_trial(db, "clinic", clinic.id)
    assert first is not None

    second = await subs.start_trial(db, "clinic", clinic.id)
    assert second is None


async def test_get_plan_returns_free_when_no_subscription(db, make_clinic):
    """Без подписки план = 'free'."""
    clinic = await make_clinic()
    plan = await subs.get_plan(db, "clinic", clinic.id)
    assert plan == "free"


async def test_get_plan_returns_pro_during_trial(db, make_clinic):
    """Во время триала план = 'pro'."""
    clinic = await make_clinic()
    await subs.start_trial(db, "clinic", clinic.id)
    plan = await subs.get_plan(db, "clinic", clinic.id)
    assert plan == "pro"


async def test_expired_subscription_falls_back_to_free(db, make_clinic):
    """Истёкшая подписка → план снова 'free' через get_plan."""
    clinic = await make_clinic()
    await subs.set_plan_manual(db, "clinic", clinic.id, "pro", days=-1)  # уже истекла
    plan = await subs.get_plan(db, "clinic", clinic.id)
    assert plan == "free"


async def test_doctor_limit_for_free(db):
    """Лимит врачей на Free = 4."""
    assert subs.get_doctor_limit("free") == 4
    assert subs.get_doctor_limit("pro") is None
    assert subs.get_doctor_limit("premium") is None


async def test_branch_limit_for_free(db):
    """Лимит филиалов на Free = 9."""
    assert subs.get_branch_limit("free") == 9
    assert subs.get_branch_limit("pro") is None
    assert subs.get_branch_limit("premium") is None


async def test_count_active_doctors(db, make_clinic, make_doctor):
    clinic = await make_clinic()
    await make_doctor(clinic=clinic, status="active")
    await make_doctor(clinic=clinic, status="active")
    await make_doctor(clinic=clinic, status="pending")
    await make_doctor(clinic=clinic, status="deactivated")
    count = await subs.count_active_doctors(db, clinic.id)
    assert count == 2  # только active


async def test_set_plan_manual_creates_premium(db, make_clinic):
    """set_plan_manual создаёт новую активную подписку и закрывает старые."""
    clinic = await make_clinic()
    await subs.start_trial(db, "clinic", clinic.id)

    new_sub = await subs.set_plan_manual(db, "clinic", clinic.id, "premium", days=30)

    assert new_sub.plan == "premium"
    assert new_sub.is_trial is False
    assert new_sub.status == "active"

    # Текущий активный план = premium
    plan = await subs.get_plan(db, "clinic", clinic.id)
    assert plan == "premium"


async def test_has_analytics_access_only_for_premium(db, make_clinic):
    """Доступ к отчётам — только Premium (или grace-период)."""
    clinic = await make_clinic()

    # Free → нет
    assert await subs.has_analytics_access(db, "clinic", clinic.id) is False

    # Pro → нет
    await subs.set_plan_manual(db, "clinic", clinic.id, "pro", days=30)
    assert await subs.has_analytics_access(db, "clinic", clinic.id) is False

    # Premium → да
    await subs.set_plan_manual(db, "clinic", clinic.id, "premium", days=30)
    assert await subs.has_analytics_access(db, "clinic", clinic.id) is True


async def test_has_analytics_access_grace_period(db, make_clinic):
    """В течение 30 дней после окончания Premium доступ к отчётам сохраняется."""
    clinic = await make_clinic()
    # Premium закончился 10 дней назад → grace ещё действует
    await subs.set_plan_manual(db, "clinic", clinic.id, "premium", days=-10)
    assert await subs.has_analytics_access(db, "clinic", clinic.id) is True

    # Premium закончился 40 дней назад → grace истёк
    await db.execute(
        # Подменим expires_at на 40 дней назад в той же подписке
        __import__("sqlalchemy").sql.text(
            "UPDATE subscriptions SET expires_at = NOW() - INTERVAL '40 days' "
            "WHERE owner_type='clinic' AND owner_id = :cid"
        ),
        {"cid": clinic.id},
    )
    await db.flush()
    assert await subs.has_analytics_access(db, "clinic", clinic.id) is False
