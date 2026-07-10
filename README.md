## GridX Infra

Contains the core infrastructure of the GridX - P2P energy trading platform

### Bootstrapped services

It currently bootstraps and runs the following services:

| Service Name | Container Name | Internal Port | Host (External) Port | Protocol | Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Mosquitto** | `gridx-mqtt` | `1883` | `1883` | TCP / MQTT | Message broker handling real-time telemetry from the IoT Smart Meter Simulator. |
| **Redis** | `gridx-redis` | `6379` | `6379` | TCP / RESP | In-memory event stream buffer and high-speed data store for system coordination. |
| **PostgreSQL** | `gridx-postgres` | `5432` | `5432` | TCP / SQL | Persistent relational database storing isolated transactional schemas for Auth, Orders, Billing, and Notifications. |
| **TimescaleDB** | `gridx-timescaledb` | `5432` | `5433` | TCP / SQL | Specialized time-series database optimized for storing large volumes of historical IoT metrics and market ticker data. |