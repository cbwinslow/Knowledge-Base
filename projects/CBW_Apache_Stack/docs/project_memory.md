# Project Memory (This Server)

- Airflow on Postgres (127.0.0.1:5432) and web UI via reserved port.
- Superset on reserved port; Postgres backend.
- Kafka (KRaft), Solr, NiFi, OpenSearch optional; all localhost-bound.
- Metrics via Prometheus/Grafana; exporters running with port guard.
