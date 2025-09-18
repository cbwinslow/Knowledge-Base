# Project Memory (This Server)
- Airflow on Postgres; web on reserved port.
- Superset on localhost reserved port, Postgres backend.
- Guacamole on Tomcat (localhost), guacd running.
- Tika server on reserved port 9998 (default).
- Kafka (KRaft), Solr, NiFi, OpenSearch optional; all localhost-bound.
- Metrics via Prometheus/Grafana; exporters running with port guard.
