#!/bin/bash

echo "========================================"
echo " GridX Infrastructure Health Check"
echo "========================================"

echo ""
echo "[1/7] Docker Containers"
sudo docker compose ps

echo ""
echo "[2/7] Redis"
sudo docker exec gridx-infra-redis-1 redis-cli ping

echo ""
echo "[3/7] PostgreSQL"
sudo docker exec gridx-infra-postgres-1 pg_isready

echo ""
echo "[4/7] TimescaleDB"
sudo docker exec gridx-infra-timescaledb-1 pg_isready

echo ""
echo "[5/7] Kafka Topics"
sudo docker exec gridx-infra-kafka-1 \
  kafka-topics \
  --bootstrap-server localhost:9092 \
  --list

echo ""
echo "[6/7] Kafka Connect"
curl -s http://localhost:8083/

echo ""
echo "[7/7] MQTT Broker"
sudo docker exec gridx-infra-mosquitto-1 \
  mosquitto_sub \
  -h localhost \
  -t '$SYS/broker/version' \
  -C 1

echo ""
echo "========================================"
echo " Infrastructure Check Complete"
echo "========================================"