#!/bin/bash

# GridX — Kafka Connect Connector Registration Script
# Registers MQTT source connectors with the Kafka Connect REST API
# Run this after docker compose up -d and Kafka Connect is healthy

KAFKA_CONNECT_URL="http://localhost:8083"

echo "[GridX] Waiting for Kafka Connect to be ready..."
until curl -s "$KAFKA_CONNECT_URL/connectors" > /dev/null 2>&1; do
  sleep 2
  echo "[GridX] Waiting..."
done
echo "[GridX] Kafka Connect is ready."

echo "[GridX] Registering mqtt-meter-source connector..."
curl -X POST -H "Content-Type: application/json" \
  --data @mqtt-connector-meter.json \
  "$KAFKA_CONNECT_URL/connectors"
echo ""

echo "[GridX] Registering mqtt-heartbeat-source connector..."
curl -X POST -H "Content-Type: application/json" \
  --data @mqtt-connector-heartbeat.json \
  "$KAFKA_CONNECT_URL/connectors"
echo ""

echo "[GridX] Verifying connectors..."
curl -s "$KAFKA_CONNECT_URL/connectors" | tr ',' '\n'
echo ""

echo "[GridX] Done. Both connectors registered."
