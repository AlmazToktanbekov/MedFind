#!/bin/bash
# Первичная выдача TLS-сертификата Let's Encrypt.
# Запускать ОДИН раз после `docker compose up -d` (когда DNS домена уже указывает на сервер).
# Повторные продления делает сервис `certbot` из docker-compose автоматически.
set -e

# Грузим DOMAIN / CERTBOT_EMAIL из .env рядом с docker-compose.yml
if [ -f .env ]; then
  set -a; . ./.env; set +a
fi

DOMAIN="${DOMAIN:?DOMAIN не задан — пропиши его в .env}"
EMAIL="${CERTBOT_EMAIL:?CERTBOT_EMAIL не задан — пропиши его в .env}"
STAGING="${STAGING:-0}"   # STAGING=1 — тестовый сертификат Let's Encrypt (без лимитов)

CERT_PATH="/etc/letsencrypt/live/$DOMAIN"

echo "── 1. Временный самоподписанный сертификат (чтобы nginx смог стартовать) ──"
docker compose run --rm --entrypoint "\
  sh -c 'mkdir -p $CERT_PATH && \
  openssl req -x509 -nodes -newkey rsa:2048 -days 1 \
    -keyout $CERT_PATH/privkey.pem \
    -out $CERT_PATH/fullchain.pem \
    -subj /CN=localhost'" certbot

echo "── 2. Запуск/перезапуск nginx ──"
docker compose up -d nginx
sleep 3

echo "── 3. Удаление временного сертификата ──"
docker compose run --rm --entrypoint "\
  rm -rf /etc/letsencrypt/live/$DOMAIN /etc/letsencrypt/archive/$DOMAIN /etc/letsencrypt/renewal/$DOMAIN.conf" certbot

echo "── 4. Запрос настоящего сертификата у Let's Encrypt ──"
STAGING_ARG=""
[ "$STAGING" != "0" ] && STAGING_ARG="--staging"
docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $STAGING_ARG \
    --email $EMAIL --agree-tos --no-eff-email \
    -d $DOMAIN" certbot

echo "── 5. Перезагрузка nginx с настоящим сертификатом ──"
docker compose exec nginx nginx -s reload || docker compose restart nginx

echo ""
echo "✅ HTTPS настроен: https://$DOMAIN"
echo "   Продление сертификата — автоматически сервисом certbot."
