# GridX Monitoring

## Overview
GridX uses Prometheus for metrics collection and Grafana for visualization. Monitoring services communicate over the internal Docker network.

## Access
| Service | URL |
|---|---|
| Prometheus | http://localhost:9090 |
| Targets | http://localhost:9090/targets |
| Alerts | http://localhost:9090/alerts |
| Grafana | http://localhost:3001 |

## Monitored services
| Service | Integration | Endpoint |
|---|---|---|
| PostgreSQL | PostgreSQL Exporter | `postgres-exporter:9187` |
| TimescaleDB | PostgreSQL Exporter | `timescale-exporter:9187` |
| Redis | Redis Exporter | `redis-exporter:9121` |
| Kafka | JMX Exporter | `kafka:9404` |
| Kafka Connect | JMX Exporter | `kafka-connect:9405` |
| Mosquitto | Mosquitto Exporter | `mosquitto-exporter:9234` |
| MinIO | Native metrics | `minio:9000/minio/v2/metrics/cluster` |

Prometheus scrape interval: 15 seconds.

## Grafana dashboards
| Dashboard | UID |
|---|---|
| Infrastructure Overview | `gridx-infra-overview` |
| Databases and Cache | `gridx-databases-cache` |
| Messaging and IoT | `gridx-messaging-iot` |
| Object Storage | `gridx-object-storage` |

Four dashboards contain 48 panels.

## Alert rules
| Alert | Severity | Condition |
|---|---|---|
| `MonitoringTargetDown` | Critical | Target unavailable for 2 minutes |
| `PostgreSQLUnavailable` | Critical | Database unavailable for 2 minutes |
| `RedisUnavailable` | Critical | Redis unavailable for 2 minutes |
| `MinIOClusterUnhealthy` | Critical | MinIO cluster unhealthy for 2 minutes |
| `MinIODriveOffline` | Warning | MinIO drive offline for 2 minutes |
| `MinIOCapacityLow` | Warning | Usable capacity below 15% for 5 minutes |

Prometheus evaluates these rules. Alertmanager and external notifications are not configured.

## Configuration files
Monitoring configuration is stored under `monitoring/prometheus/` and `monitoring/grafana/`. The MinIO bearer token is stored locally at `monitoring/prometheus/minio-token`, ignored by Git, and mounted read-only. Never commit or expose its contents.

## Validation and troubleshooting
Run these commands from the repository root.

### Docker Compose
```bash
docker compose config --quiet
```

### Prometheus configuration
```bash
docker compose exec -T prometheus promtool check config /etc/prometheus/prometheus.yml
```

### Alert rules
```bash
docker compose exec -T prometheus promtool check rules /etc/prometheus/alerts/infrastructure.yml
```

### Grafana health
```bash
curl -fsS http://localhost:3001/api/health
```

Check Prometheus targets at http://localhost:9090/targets and dashboards at http://localhost:3001.

## Persistence and operational notes
- Prometheus data is stored in `prometheus_data`.
- Grafana data is stored in `grafana_data`.
- Infrastructure services use their configured persistent volumes.
- Exporters communicate over the internal Docker network.
- Avoid `docker compose down -v`; it removes named volumes and can destroy persistent data.
- Monitoring provides observability, not high availability or a guarantee of physical energy transfers.
