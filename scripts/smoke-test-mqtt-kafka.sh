#!/usr/bin/env bash

set -euo pipefail

MQTT_TOPIC="gridx/smoke-test/device-1/meter"
KAFKA_TOPIC="iot.meter-readings"
TEST_ID="gridx-smoke-$(date +%s)"
TEST_PAYLOAD="{\"testId\":\"${TEST_ID}\",\"watts\":123.45}"

OUTPUT_FILE="$(mktemp)"
CONSUMER_PID=""

cleanup() {
  if [ -n "$CONSUMER_PID" ]; then
    kill "$CONSUMER_PID" >/dev/null 2>&1 || true
  fi

  rm -f "$OUTPUT_FILE"
}

trap cleanup EXIT

echo "[GridX] Starting Kafka consumer..."

docker compose exec -T kafka \
  kafka-console-consumer \
  --bootstrap-server kafka:29092 \
  --topic "$KAFKA_TOPIC" \
  --consumer-property auto.offset.reset=latest \
  --timeout-ms 15000 \
  >"$OUTPUT_FILE" 2>&1 &

CONSUMER_PID=$!

# Give the consumer time to establish its Kafka connection.
sleep 3

echo "[GridX] Publishing MQTT message to ${MQTT_TOPIC}..."

docker compose exec -T mosquitto \
  mosquitto_pub \
  -h localhost \
  -p 1883 \
  -q 1 \
  -t "$MQTT_TOPIC" \
  -m "$TEST_PAYLOAD"

wait "$CONSUMER_PID" || true
CONSUMER_PID=""

if grep -q "$TEST_ID" "$OUTPUT_FILE"; then
  echo "[GridX] MQTT-to-Kafka smoke test passed."
  echo "[GridX] Received payload: ${TEST_PAYLOAD}"
else
  echo "[GridX] MQTT-to-Kafka smoke test failed." >&2
  echo "[GridX] Kafka consumer output:" >&2
  cat "$OUTPUT_FILE" >&2
  exit 1
fi