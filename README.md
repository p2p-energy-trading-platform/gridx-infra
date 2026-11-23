# GridX Infra

Contains the core infrastructure of the GridX P2P energy trading platform.

## Bootstrapped services

It currently bootstraps and runs the following services:

| Service Name | Container Name | Internal Port | Host (External) Port | Protocol | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Mosquitto** | `gridx-mqtt` | `1883` | `1883` | TCP / MQTT | Message broker handling real-time telemetry from the IoT Smart Meter Simulator. |
| **Kafka** | `gridx-kafka` | `9092` (external), `29092` (internal) | `9092` | TCP / Binary | High-throughput distributed event streaming platform for message orchestration across microservices. |
| **Kafka Connect** | Compose service `kafka-connect` | `8083` | `8083` | HTTP | Runs and manages the MQTT source connectors. |
| **Kafka UI** | UI view for kafka and kafka connect | `8080` | `8080` | HTTP | Shows dashboard view of kafka |
| **Redis** | `gridx-redis` | `6379` | `6379` | TCP / RESP | In-memory event stream buffer and high-speed data store for system coordination. |
| **PostgreSQL** | `gridx-postgres` | `5432` | `5432` | TCP / SQL | Persistent relational database storing isolated transactional schemas for Auth, Orders, Billing, and Notifications. |
| **TimescaleDB** | `gridx-timescaledb` | `5432` | `5433` | TCP / SQL | Specialized time-series database optimized for storing large volumes of historical IoT metrics and market ticker data. |
| **MinIO** | `girdx-minio` | `9000` (S3 API), `9001` (Console) | `9000` (S3 API), `9001` (Console) | HTTP / S3-compatible API | Object storage for uploaded files, documents, reports, and exports, with persistent data stored in a Docker named volume. |

## Monitoring and observability

GridX uses **Prometheus** for infrastructure metrics collection and
**Grafana** for monitoring dashboards. Both services run through Docker
Compose and communicate with infrastructure services over the internal
Docker network.

### Accessing monitoring

When running locally, the monitoring interfaces are available at:

| Service | URL | Purpose |
|---|---|---|
| Prometheus | http://localhost:9090 | Metrics collection and querying |
| Prometheus Targets | http://localhost:9090/targets | Scrape target health |
| Prometheus Alerts | http://localhost:9090/alerts | Alert rule status |
| Grafana | http://localhost:3001 | Monitoring dashboards |

Grafana credentials are configured through `GRAFANA_ADMIN_USER` and
`GRAFANA_ADMIN_PASSWORD` in the environment configuration.

### Monitored infrastructure

Prometheus collects metrics from the following infrastructure components:

- **PostgreSQL and TimescaleDB** — database metrics through PostgreSQL exporters.
- **Redis** — cache and datastore metrics through the Redis exporter.
- **Kafka and Kafka Connect** — JVM metrics through JMX exporters.
- **Mosquitto** — MQTT broker metrics through the Mosquitto exporter.
- **MinIO** — object storage metrics through its native Prometheus endpoint.

### Grafana dashboards

Four provisioned dashboards provide visibility across the infrastructure:

| Dashboard | Coverage |
|---|---|
| Infrastructure Overview | Overall infrastructure health |
| Databases and Cache | PostgreSQL, TimescaleDB, and Redis |
| Messaging and IoT | Kafka, Kafka Connect, and Mosquitto |
| Object Storage | MinIO storage health and capacity |

The dashboards contain **48 monitoring panels** in total.

### Prometheus alert rules

Six alert rules are configured to detect infrastructure availability
and storage-related conditions:

- `MonitoringTargetDown`
- `PostgreSQLUnavailable`
- `RedisUnavailable`
- `MinIOClusterUnhealthy`
- `MinIODriveOffline`
- `MinIOCapacityLow`

Prometheus evaluates these rules. Alertmanager and external notification
delivery are not currently configured.

For detailed configuration, validation commands, and operational notes,
see the [Monitoring Documentation](monitoring/README.md).

## Starting the infrastructure

Start all infrastructure services and initialize both MQTT source connectors.

Refer to `gridx-workspace` startup commands.

Check container and connector health:

```bash
./scripts/health-check.sh
```

Run the MQTT-to-Kafka integration test:

```bash
./scripts/smoke-test-mqtt-kafka.sh
```

**Note:** Remember to run `chmod +x <script-name>` if the scripts do not have executable permissions.

### MinIO access

When running locally, the MinIO endpoints are:

- **S3 API:** `http://localhost:9000`
- **Web Console:** `http://localhost:9001`

Use the credentials configured through `MINIO_ROOT_USER` and `MINIO_ROOT_PASSWORD` in the environment configuration. Do not commit real credentials to version control.

Services running on `gridx-infra-network` should connect to MinIO using `http://minio:9000` rather than `localhost:9000`.

MinIO stores the actual objects, while application services can store object keys and associated metadata in PostgreSQL. The `minio_data` Docker volume provides persistence across container recreation.

## MQTT-to-Kafka routing

| MQTT topic filter | Kafka topic | Connector |
| --- | --- | --- |
| `gridx/+/+/meter` | `iot.meter-readings` | `mqtt-meter-source` |
| `gridx/+/+/heartbeat` | `iot.heartbeats` | `mqtt-heartbeat-source` |

Kafka Connect subscribes to Mosquitto using the two MQTT source connectors. MQTT payloads are written to Kafka as raw bytes, and the original MQTT topic becomes the Kafka record key.