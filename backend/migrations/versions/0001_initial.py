"""Initial schema — all tables

Revision ID: 0001
Revises:
Create Date: 2026-04-07

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = "0001"
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_table(
        "users",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("phone", sa.String(20), unique=True, nullable=False, index=True),
        sa.Column("full_name", sa.String(255)),
        sa.Column("email", sa.String(255), unique=True),
        sa.Column("password_hash", sa.String(255)),
        sa.Column("role", sa.String(20), nullable=False, server_default="patient"),
        sa.Column("avatar_url", sa.String(512)),
        sa.Column("is_active", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "otp_codes",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("phone", sa.String(20), nullable=False, index=True),
        sa.Column("code", sa.String(10), nullable=False),
        sa.Column("is_used", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("expires_at", sa.DateTime(timezone=True), nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "clinics",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer),
        sa.Column("name_ru", sa.String(255), nullable=False),
        sa.Column("name_kg", sa.String(255)),
        sa.Column("name_en", sa.String(255)),
        sa.Column("description_ru", sa.Text),
        sa.Column("description_kg", sa.Text),
        sa.Column("description_en", sa.Text),
        sa.Column("category_ru", sa.String(255)),
        sa.Column("category_kg", sa.String(255)),
        sa.Column("category_en", sa.String(255)),
        sa.Column("address_ru", sa.String(512)),
        sa.Column("address_kg", sa.String(512)),
        sa.Column("address_en", sa.String(512)),
        sa.Column("phone", sa.String(30)),
        sa.Column("website", sa.String(255)),
        sa.Column("photo_url", sa.String(512)),
        sa.Column("latitude", sa.Float),
        sa.Column("longitude", sa.Float),
        sa.Column("rating", sa.Float, nullable=False, server_default="0"),
        sa.Column("reviews_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("working_hours_ru", sa.String(255)),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "doctors",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id"), unique=True),
        sa.Column("full_name_ru", sa.String(255), nullable=False),
        sa.Column("full_name_kg", sa.String(255)),
        sa.Column("full_name_en", sa.String(255)),
        sa.Column("specialization_ru", sa.String(255), nullable=False),
        sa.Column("specialization_kg", sa.String(255)),
        sa.Column("specialization_en", sa.String(255)),
        sa.Column("bio_ru", sa.Text),
        sa.Column("bio_kg", sa.Text),
        sa.Column("bio_en", sa.Text),
        sa.Column("photo_url", sa.String(512)),
        sa.Column("experience_years", sa.Integer),
        sa.Column("clinic_id", sa.Integer, sa.ForeignKey("clinics.id")),
        sa.Column("has_online", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("has_offline", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("online_price", sa.Float),
        sa.Column("offline_price", sa.Float),
        sa.Column("online_duration_min", sa.Integer, server_default="30"),
        sa.Column("offline_duration_min", sa.Integer, server_default="30"),
        sa.Column("rating", sa.Float, nullable=False, server_default="0"),
        sa.Column("reviews_count", sa.Integer, nullable=False, server_default="0"),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "doctor_contacts",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("doctor_id", sa.Integer, sa.ForeignKey("doctors.id"), nullable=False),
        sa.Column("type", sa.String(30), nullable=False),
        sa.Column("value", sa.String(255), nullable=False),
    )

    op.create_table(
        "doctor_services",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("doctor_id", sa.Integer, sa.ForeignKey("doctors.id"), nullable=False),
        sa.Column("name_ru", sa.String(255), nullable=False),
        sa.Column("name_kg", sa.String(255)),
        sa.Column("name_en", sa.String(255)),
        sa.Column("price", sa.Float),
    )

    op.create_table(
        "doctor_schedules",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("doctor_id", sa.Integer, sa.ForeignKey("doctors.id"), nullable=False),
        sa.Column("day_of_week", sa.Integer, nullable=False),
        sa.Column("start_time", sa.String(5), nullable=False),
        sa.Column("end_time", sa.String(5), nullable=False),
        sa.Column("is_available", sa.Boolean, nullable=False, server_default="true"),
    )

    op.create_table(
        "pharmacies",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer),
        sa.Column("name_ru", sa.String(255), nullable=False),
        sa.Column("name_kg", sa.String(255)),
        sa.Column("name_en", sa.String(255)),
        sa.Column("address_ru", sa.String(512)),
        sa.Column("address_kg", sa.String(512)),
        sa.Column("address_en", sa.String(512)),
        sa.Column("phone", sa.String(30)),
        sa.Column("photo_url", sa.String(512)),
        sa.Column("latitude", sa.Float),
        sa.Column("longitude", sa.Float),
        sa.Column("is_open_24h", sa.Boolean, nullable=False, server_default="false"),
        sa.Column("working_hours_ru", sa.String(255)),
        sa.Column("status", sa.String(20), nullable=False, server_default="pending"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "symptoms",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("name_ru", sa.String(255), nullable=False),
        sa.Column("name_kg", sa.String(255)),
        sa.Column("name_en", sa.String(255)),
        sa.Column("icon", sa.String(100)),
    )

    op.create_table(
        "symptom_specializations",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("symptom_id", sa.Integer, sa.ForeignKey("symptoms.id"), nullable=False),
        sa.Column("specialization_ru", sa.String(255), nullable=False),
        sa.Column("specialization_kg", sa.String(255)),
        sa.Column("specialization_en", sa.String(255)),
    )

    op.create_table(
        "reviews",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("author_id", sa.Integer, sa.ForeignKey("users.id"), nullable=False),
        sa.Column("doctor_id", sa.Integer, sa.ForeignKey("doctors.id")),
        sa.Column("clinic_id", sa.Integer, sa.ForeignKey("clinics.id")),
        sa.Column("rating", sa.Float, nullable=False),
        sa.Column("text", sa.Text),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "articles",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("title_ru", sa.String(512), nullable=False),
        sa.Column("title_kg", sa.String(512)),
        sa.Column("title_en", sa.String(512)),
        sa.Column("body_ru", sa.Text),
        sa.Column("body_kg", sa.Text),
        sa.Column("body_en", sa.Text),
        sa.Column("category", sa.String(50)),
        sa.Column("image_url", sa.String(512)),
        sa.Column("is_published", sa.Boolean, nullable=False, server_default="true"),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )

    op.create_table(
        "favorites",
        sa.Column("id", sa.Integer, primary_key=True),
        sa.Column("user_id", sa.Integer, sa.ForeignKey("users.id"), nullable=False),
        sa.Column("entity_type", sa.String(20), nullable=False),
        sa.Column("entity_id", sa.Integer, nullable=False),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False, server_default=sa.func.now()),
    )


def downgrade() -> None:
    op.drop_table("favorites")
    op.drop_table("articles")
    op.drop_table("reviews")
    op.drop_table("symptom_specializations")
    op.drop_table("symptoms")
    op.drop_table("pharmacies")
    op.drop_table("doctor_schedules")
    op.drop_table("doctor_services")
    op.drop_table("doctor_contacts")
    op.drop_table("doctors")
    op.drop_table("clinics")
    op.drop_table("otp_codes")
    op.drop_table("users")
