#!/bin/bash
# Первичная установка MedFind на сервере с НЕСКОЛЬКИМИ проектами (Ubuntu 22.04+).
# На хосте уже стоит nginx + certbot — они работают реверс-прокси и TLS для всех *.softjol.site.
# Этот compose поднимает только БД + бэкенд; бэкенд слушает 127.0.0.1:8010.
# Запускать из каталога проекта: bash deploy.sh
set -e

APP_DIR="/srv/MedFind"
DOMAIN="medfind.softjol.site"
BACKEND_PORT="8010"

cd "$(dirname "$0")"

echo "── 1. Проверка Docker ──────────────────────────────────"
if ! command -v docker &>/dev/null; then
  echo "Docker не установлен. Установка..."
  apt-get update -qq
  apt-get install -y ca-certificates curl gnupg
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable docker
else
  echo "Docker уже установлен"
fi

echo "── 2. Конфиги (.env) ───────────────────────────────────"
NEED_EDIT=0
if [ ! -f .env ]; then
  cp .env.example .env
  NEED_EDIT=1
fi
if [ ! -f backend/.env ]; then
  cp backend/.env.example backend/.env
  NEED_EDIT=1
fi
if [ "$NEED_EDIT" = "1" ]; then
  echo ""
  echo "⚠️  Заполни конфиги и запусти скрипт снова:"
  echo "   nano $APP_DIR/.env"
  echo "       POSTGRES_PASSWORD=<сильный пароль БД>"
  echo "   nano $APP_DIR/backend/.env"
  echo "       DATABASE_URL=postgresql+asyncpg://medfind_user:<тот же пароль>@db:5432/medfind_db"
  echo "       SYNC_DATABASE_URL=postgresql://medfind_user:<тот же пароль>@db:5432/medfind_db"
  echo "       SECRET_KEY=<python3 -c 'import secrets; print(secrets.token_hex(32))'>"
  echo "       DEV_MODE=false"
  echo "   (опц.) положи backend/serviceAccountKey.json для push-уведомлений"
  exit 0
fi
echo "Конфиги на месте"

echo "── 3. Сборка и запуск (db + backend на 127.0.0.1:$BACKEND_PORT) ──"
docker compose up -d --build

echo "── 4. Миграции ─────────────────────────────────────────"
sleep 5
docker compose exec -T backend alembic upgrade head

echo ""
echo "✅ Бэкенд работает: http://127.0.0.1:$BACKEND_PORT  (проверь: curl -s localhost:$BACKEND_PORT/health)"
echo ""
echo "── 5. Хостовый nginx ───────────────────────────────────"
echo "   sudo cp $APP_DIR/nginx/medfind.conf /etc/nginx/sites-available/$DOMAIN"
echo "   sudo ln -s /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/"
echo "   sudo nginx -t && sudo systemctl reload nginx"
echo ""
echo "── 6. HTTPS (Let's Encrypt через хостовый certbot) ─────"
echo "   Убедись, что DNS $DOMAIN указывает на этот сервер, затем:"
echo "   sudo certbot --nginx -d $DOMAIN"
echo "   Продление — автоматически (systemd-таймер certbot)."
