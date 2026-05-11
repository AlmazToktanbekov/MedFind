#!/bin/bash
# Скрипт первичной установки на сервере (Ubuntu 22.04+)
# Запускать один раз: bash deploy.sh
set -e

REPO="https://github.com/AlmazToktanbekov/MedFind.git"
APP_DIR="/opt/medfind"

echo "── 1. Установка Docker ──────────────────────────────────"
if ! command -v docker &>/dev/null; then
  apt-get update -qq
  apt-get install -y ca-certificates curl gnupg openssl
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
    > /etc/apt/sources.list.d/docker.list
  apt-get update -qq
  apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable docker
  echo "Docker установлен"
else
  echo "Docker уже установлен"
fi

echo "── 2. Клонирование репозитория ─────────────────────────"
if [ -d "$APP_DIR" ]; then
  echo "Директория уже существует, обновляем..."
  git -C "$APP_DIR" pull origin master
else
  git clone "$REPO" "$APP_DIR"
fi
cd "$APP_DIR"

echo "── 3. Создание конфигов (.env) ─────────────────────────"
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
  echo "⚠️  ВАЖНО: отредактируй конфиги перед запуском:"
  echo "   nano $APP_DIR/.env            # POSTGRES_PASSWORD, DOMAIN, CERTBOT_EMAIL"
  echo "   nano $APP_DIR/backend/.env    # тот же пароль БД, SECRET_KEY, DEV_MODE=false"
  echo ""
  echo "   В backend/.env синхронизируй с .env:"
  echo "   - DATABASE_URL / SYNC_DATABASE_URL — пароль = POSTGRES_PASSWORD, хост = db"
  echo "   - SECRET_KEY — python3 -c 'import secrets; print(secrets.token_hex(32))'"
  echo "   - DEV_MODE=false"
  echo "   - (опц.) положи serviceAccountKey.json в backend/ для push-уведомлений"
  echo ""
  echo "После редактирования запусти снова: bash deploy.sh"
  exit 0
else
  echo "Конфиги уже существуют"
fi

echo "── 4. Запуск сервисов ──────────────────────────────────"
docker compose up -d --build

echo "── 5. Применение миграций ──────────────────────────────"
sleep 5
docker compose exec -T backend alembic upgrade head

echo ""
echo "✅ Бэкенд запущен на 80 порту: http://$(hostname -I | awk '{print $1}')"
echo ""
echo "── 6. Настройка HTTPS ──────────────────────────────────"
echo "   Убедись, что DNS домена (DOMAIN из .env) указывает на этот сервер, затем:"
echo "   bash init-letsencrypt.sh"
echo ""
echo "   (сначала можно проверить тестовым сертификатом: STAGING=1 bash init-letsencrypt.sh)"
echo "   Дальнейшее продление сертификата — автоматически сервисом certbot."
