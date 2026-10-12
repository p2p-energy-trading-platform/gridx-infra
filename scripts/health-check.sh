#!/bin/sh

set -eu

KAFKA_CONNECT_URL="${KAFKA_CONNECT_URL:-http://localhost:8083}"
MINIO_URL="${MINIO_URL:-http://localhost:9000}"

# Same project name as `task infra-up` and the workspace root compose file,
# so the script finds the running containers from any directory.
SCRIPT_DIRECTORY="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
export COMPOSE_FILE="${COMPOSE_FILE:-$(dirname "$SCRIPT_DIRECTORY")/docker-compose.yml}"
export COMPOSE_PROJECT_NAME="${COMPOSE_PROJECT_NAME:-gridx-infrastructure}"

echo "========================================"
echo " GridX Infrastructure Health Check"
echo "========================================"

echo
echo "[1/9] Docker containers"
docker compose ps

echo
echo "[2/9] Redis"
docker compose exec -T redis redis-cli ping

echo
echo "[3/9] PostgreSQL"
docker compose exec -T postgres \
  pg_isready \
  -U "${POSTGRES_USER:-gridx_master_user}" \
  -d "${POSTGRES_DB:-gridx_db}"

echo
echo "[4/9] TimescaleDB"
docker compose exec -T timescaledb \
  pg_isready \
  -U "${TIMESCALE_USER:-gridx_timescale_master}" \
  -d "${TIMESCALE_DB:-gridx_timescaledb}"

echo
echo "[5/9] Kafka"
docker compose exec -T kafka \
  kafka-topics \
  --bootstrap-server kafka:29092 \
  --list

echo
echo "[6/9] Kafka Connect"
curl --fail --silent --show-error "${KAFKA_CONNECT_URL}/"

echo
echo "[7/9] MQTT meter connector"
curl \
  --fail \
  --silent \
  --show-error \
  "${KAFKA_CONNECT_URL}/connectors/mqtt-meter-source/status"

echo
echo
echo "[8/9] MQTT heartbeat connector"
curl \
  --fail \
  --silent \
  --show-error \
  "${KAFKA_CONNECT_URL}/connectors/mqtt-heartbeat-source/status"

echo
echo
echo "[9/9] MinIO"
curl --fail --silent --show-error "${MINIO_URL}/minio/health/live"
echo "MinIO is live"
docker compose exec -T minio sh -c \
  'mc alias set local http://localhost:9000 "$MINIO_ROOT_USER" "$MINIO_ROOT_PASSWORD" >/dev/null && mc ls local'

echo
echo "========================================"
echo " Infrastructure Check Complete"
echo "========================================"