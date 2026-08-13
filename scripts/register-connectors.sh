#!/bin/bash

# GridX — Kafka Connect Connector Registration Script
# Registers MQTT source connectors with the Kafka Connect REST API
# Run this after docker compose up -d and Kafka Connect is healthy

set -eu

KAFKA_CONNECT_URL="${KAFKA_CONNECT_URL:-http://localhost:8083}"
CONNECT_TIMEOUT_SECONDS="${CONNECT_TIMEOUT_SECONDS:-120}"

SCRIPT_DIRECTORY="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
REPOSITORY_ROOT="$(dirname "$SCRIPT_DIRECTORY")"

wait_for_connect() {
  elapsed=0

  echo "[GridX] Waiting for kafka connect at ${KAFKA_CONNECT_URL}..."

  until curl -fsS "${KAFKA_CONNECT_URL}/connectors" >/dev/null 2>&1; do
    if [ "$elapsed" -ge "CONNECT_TIMEOUT_SECONDS" ]; then
      echo "[GridX] Kafka connect did not become available with ${CONNECT_TIMEOUT_SECONDS} seconds.." >&2
      return 1
    fi

    sleep 2
    elapsed=$((elapsed + 2))
  done

  echo "[GridX] Kafka Connector is ready"
}

apply_connector() {
  connector_name="$1"
  config_file="$2"

  echo "[GridX] Applying ${connector_name}..."

  curl \
    --fail-with-body \
    --silent \
    --show-error \
    --request PUT \
    --header "Content-Type: application/json" \
    --data-binary "@${config_file}" \
    "${KAFKA_CONNECT_URL}/connectors/${connector_name}/config"

  echo "[GridX] Applied ${connector_name}"
}

wait_for_connector() {
  connector_name="$1"
  elapsed=0

  echo "[GridX] Waiting for ${connector_name} to reach RUNNING..."

  while [ "$elapsed" -lt "$CONNECT_TIMEOUT_SECONDS" ]; do
    status="$(
      curl \
        --fail \
        --silent \
        --show-error \
        "${KAFKA_CONNECT_URL}/connectors/${connector_name}/status"
    )"

    if echo "$status" | grep -q '"state":"FAILED"'; then
      echo "[GridX] ${connector_name} failed:" >&2
      echo "$status" >&2
      return 1
    fi

    running_states="$(
      echo "$status" |
        grep -o '"state":"RUNNING"' |
        wc -l |
        tr -d ' '
    )"

    if [ "$running_states" -ge 2 ]; then
      echo "[GridX] ${connector_name} is running"
      return 0
    fi

    sleep 2
    elapsed=$((elapsed + 2))
  done

  echo "[GridX] ${connector_name} did not reach RUNNING state." >&2
  echo "$status" >&2
  return 1
}

wait_for_connect

apply_connector \
  "mqtt-meter-source" \
  "${REPOSITORY_ROOT}/mosquitto/mqtt-connector-meter.json"

apply_connector \
  "mqtt-heartbeat-source" \
  "${REPOSITORY_ROOT}/mosquitto/mqtt-connector-heartbeat.json"

wait_for_connector "mqtt-meter-source"
wait_for_connector "mqtt-heartbeat-source"
