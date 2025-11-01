# Monitoring Tools

Comprehensive monitoring and observability tools for applications and infrastructure.

## Metrics & Monitoring

### Prometheus
**Purpose:** Time-series metrics collection and alerting  
**Configuration:**
```yaml
tool:
  name: prometheus
  type: monitoring
  features:
    - metrics_collection
    - alerting
    - service_discovery
    - time_series_database
  config_file: prometheus.yml
  exporters:
    - node_exporter
    - blackbox_exporter
    - postgres_exporter
    - redis_exporter
```

### Grafana
**Purpose:** Metrics visualization and dashboards  
**Configuration:**
```yaml
tool:
  name: grafana
  type: visualization
  features:
    - dashboards
    - alerting
    - data_sources
    - plugins
  data_sources:
    - prometheus
    - elasticsearch
    - cloudwatch
    - datadog
```

### Datadog
**Purpose:** Full-stack monitoring platform  
**Configuration:**
```yaml
tool:
  name: datadog
  type: monitoring
  features:
    - infrastructure_monitoring
    - apm
    - log_management
    - synthetic_monitoring
    - security_monitoring
```

### New Relic
**Purpose:** Application performance monitoring  
**Configuration:**
```yaml
tool:
  name: new_relic
  type: apm
  features:
    - application_monitoring
    - infrastructure_monitoring
    - browser_monitoring
    - mobile_monitoring
    - synthetics
```

## Logging

### ELK Stack (Elasticsearch, Logstash, Kibana)
**Purpose:** Log aggregation and analysis  
**Configuration:**
```yaml
tool:
  name: elk_stack
  type: logging
  components:
    elasticsearch:
      purpose: log_storage_and_search
    logstash:
      purpose: log_processing
    kibana:
      purpose: log_visualization
  features:
    - centralized_logging
    - full_text_search
    - log_analytics
    - dashboards
```

### Fluentd
**Purpose:** Unified logging layer  
**Configuration:**
```yaml
tool:
  name: fluentd
  type: logging
  features:
    - log_collection
    - log_parsing
    - log_routing
    - output_plugins
  outputs:
    - elasticsearch
    - s3
    - cloudwatch
    - kafka
```

### Loki
**Purpose:** Log aggregation system  
**Configuration:**
```yaml
tool:
  name: loki
  type: logging
  features:
    - log_aggregation
    - label_based_indexing
    - grafana_integration
    - cost_effective
```

## Application Performance Monitoring (APM)

### OpenTelemetry
**Purpose:** Observability framework  
**Configuration:**
```yaml
tool:
  name: opentelemetry
  type: apm
  features:
    - distributed_tracing
    - metrics
    - logs
    - vendor_neutral
  components:
    - otel_collector
    - instrumentation_libraries
```

### Jaeger
**Purpose:** Distributed tracing  
**Configuration:**
```yaml
tool:
  name: jaeger
  type: tracing
  features:
    - distributed_tracing
    - root_cause_analysis
    - service_dependency_analysis
    - performance_optimization
```

### Zipkin
**Purpose:** Distributed tracing system  
**Configuration:**
```yaml
tool:
  name: zipkin
  type: tracing
  features:
    - trace_collection
    - trace_visualization
    - service_dependencies
    - latency_analysis
```

## Alerting

### PagerDuty
**Purpose:** Incident management and alerting  
**Configuration:**
```yaml
tool:
  name: pagerduty
  type: alerting
  features:
    - on_call_scheduling
    - escalation_policies
    - incident_management
    - integrations
```

### Opsgenie
**Purpose:** Alert and on-call management  
**Configuration:**
```yaml
tool:
  name: opsgenie
  type: alerting
  features:
    - alert_routing
    - on_call_schedules
    - escalations
    - integrations
```

### Alertmanager
**Purpose:** Alert handling for Prometheus  
**Configuration:**
```yaml
tool:
  name: alertmanager
  type: alerting
  features:
    - alert_grouping
    - deduplication
    - silencing
    - routing
  receivers:
    - email
    - slack
    - pagerduty
    - webhook
```

## Uptime Monitoring

### Pingdom
**Purpose:** Website and server monitoring  
**Configuration:**
```yaml
tool:
  name: pingdom
  type: uptime_monitoring
  features:
    - uptime_checks
    - performance_monitoring
    - real_user_monitoring
    - transaction_monitoring
```

### UptimeRobot
**Purpose:** Website monitoring  
**Configuration:**
```yaml
tool:
  name: uptimerobot
  type: uptime_monitoring
  features:
    - http_monitoring
    - keyword_monitoring
    - port_monitoring
    - heartbeat_monitoring
```

## Infrastructure Monitoring

### Nagios
**Purpose:** Infrastructure monitoring  
**Configuration:**
```yaml
tool:
  name: nagios
  type: infrastructure_monitoring
  features:
    - server_monitoring
    - network_monitoring
    - service_monitoring
    - alerting
```

### Zabbix
**Purpose:** Enterprise monitoring  
**Configuration:**
```yaml
tool:
  name: zabbix
  type: infrastructure_monitoring
  features:
    - agent_based_monitoring
    - agentless_monitoring
    - distributed_monitoring
    - auto_discovery
```

## Monitoring Best Practices

### The Four Golden Signals
1. **Latency:** Request response time
2. **Traffic:** Request rate
3. **Errors:** Error rate
4. **Saturation:** Resource utilization

### SRE Approach
```yaml
monitoring_strategy:
  slis:
    - availability
    - latency
    - throughput
    - error_rate
  slos:
    availability: "99.9%"
    latency_p95: "<200ms"
    error_rate: "<0.1%"
  error_budget:
    calculation: "1 - SLO"
    policy: "stop_releases_when_exhausted"
```

### Alert Design
```yaml
alert_principles:
  - actionable: "Alerts should require action"
  - clear: "Alert message should be clear"
  - documented: "Include runbook link"
  - appropriate_severity: "Match severity to impact"
  - avoid_alert_fatigue: "Don't over-alert"
```

## Integration Example

```yaml
# docker-compose.yml for monitoring stack
version: '3'
services:
  prometheus:
    image: prom/prometheus
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
  
  grafana:
    image: grafana/grafana
    ports:
      - "3000:3000"
    environment:
      - GF_SECURITY_ADMIN_PASSWORD=admin
  
  node_exporter:
    image: prom/node-exporter
    ports:
      - "9100:9100"
  
  alertmanager:
    image: prom/alertmanager
    ports:
      - "9093:9093"
```

## Best Practices

1. **Monitor What Matters:** Focus on user-impacting metrics
2. **Set Appropriate Thresholds:** Avoid false positives
3. **Automate Alerting:** Alert on anomalies, not just thresholds
4. **Create Dashboards:** Visual representation of system health
5. **Log Everything:** Comprehensive logging for debugging
6. **Distributed Tracing:** Understand request flows
7. **Retention Policies:** Balance storage costs with needs
8. **Regular Review:** Review and update monitoring regularly
9. **Documentation:** Document what you monitor and why
10. **Testing:** Test monitoring and alerting regularly
