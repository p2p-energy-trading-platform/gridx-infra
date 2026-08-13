#!/bin/sh

set -eu

KAFKA_CONNECT_URL="${KAFKA_CONNECT_URL:-http://localhost:8083}"

echo "========================================"
echo " GridX Infrastructure Health Check"
echo "========================================"

echo
echo "[1/8] Docker containers"
docker compose ps

echo
echo "[2/8] Redis"
docker compose exec -T redis redis-cli ping

echo
echo "[3/8] PostgreSQL"
docker compose exec -T postgres \
  pg_isready \
  -U "${POSTGRES_USER:-gridx_master_user}" \
  -d "${POSTGRES_DB:-gridx_db}"

echo
echo "[4/8] TimescaleDB"
docker compose exec -T timescaledb \
  pg_isready \
  -U "${TIMESCALE_USER:-gridx_timescale_master}" \
  -d "${TIMESCALE_DB:-gridx_timescaledb}"

echo
echo "[5/8] Kafka"
docker compose exec -T kafka \
  kafka-topics \
  --bootstrap-server kafka:29092 \
  --list

echo
echo "[6/8] Kafka Connect"
curl --fail --silent --show-error "${KAFKA_CONNECT_URL}/"

echo
echo "[7/8] MQTT meter connector"
curl \
  --fail \
  --silent \
  --show-error \
  "${KAFKA_CONNECT_URL}/connectors/mqtt-meter-source/status"

echo
echo
echo "[8/8] MQTT heartbeat connector"
curl \
  --fail \
  --silent \
  --show-error \
  "${KAFKA_CONNECT_URL}/connectors/mqtt-heartbeat-source/status"

echo
echo
echo "========================================"
echo " Infrastructure Check Complete"
echo "========================================"