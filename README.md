## GridX Infra

Contains the core infrastructure of the GridX - P2P energy trading platform

### Bootstrapped services

It currently bootstraps and runs the following services:

| Service Name | Container Name | Internal Port | Host (External) Port | Protocol | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Mosquitto** | `gridx-mqtt` | `1883` | `1883` | TCP / MQTT | Message broker handling real-time telemetry from the IoT Smart Meter Simulator. |
| **Kafka** | `gridx-kafka` | `9092` | `9092` | TCP / Binary | High-throughput distributed event streaming platform for message orchestration across microservices. |
| **Kafka Connect** | Compose service `kafka-connect` | `8083` | `8083` | HTTP | Runs and manages the MQTT source connectors. |
| **Redis** | `gridx-redis` | `6379` | `6379` | TCP / RESP | In-memory event stream buffer and high-speed data store for system coordination. |
| **PostgreSQL** | `gridx-postgres` | `5432` | `5432` | TCP / SQL | Persistent relational database storing isolated transactional schemas for Auth, Orders, Billing, and Notifications. |
| **TimescaleDB** | `gridx-timescaledb` | `5432` | `5433` | TCP / SQL | Specialized time-series database optimized for storing large volumes of historical IoT metrics and market ticker data. |

## Starting the infrastructure

Start all infrastructure services and initialize both MQTT source connectors:

Refer to `gridx-workspace` startup commands.

Check container and connector health:

```bash
./scripts/health-check.sh
```

Run the MQTT-to-Kafka integration test:

```bash
./scripts/smoke-test-mqtt-kafka.sh
```

NOTE: Remember to `chmod +x <script-name>` to run the above commands.

## MQTT-to-Kafka routing

| MQTT topic filter | Kafka topic | Connector |
| --- | --- | --- |
| `gridx/+/+/meter` | `iot.meter-readings` | `mqtt-meter-source` |
| `gridx/+/+/heartbeat` | `iot.heartbeats` | `mqtt-heartbeat-source` |

Kafka Connect subscribes to Mosquitto using the two MQTT source
connectors. MQTT payloads are written to Kafka as raw bytes, and the
original MQTT topic becomes the Kafka record key.

