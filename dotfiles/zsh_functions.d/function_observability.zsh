# ==============================================================================
# FILENAME: function_observability.zsh
#
# PURPOSE:
#   Lightweight observability helpers for logging, tracing, and metrics that can
#   forward events to OpenTelemetry, OpenObservability, Grafana, Loki, Alloy, or
#   local files for later ingestion.
# ==============================================================================

_cbw_obs_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

_cbw_obs_payload() {
    local level="$1"
    local message="$2"
    local context="${3:-}"
    local ts="$(_cbw_obs_timestamp)"
    if command -v jq >/dev/null 2>&1; then
        jq -n \
            --arg ts "$ts" \
            --arg lvl "$level" \
            --arg msg "$message" \
            --arg ctx "$context" \
            '{timestamp:$ts, level:$lvl, message:$msg, context:$ctx}'
    else
        python3 - "$ts" "$level" "$message" "$context" <<'PY'
import json, sys
ts, lvl, msg, ctx = sys.argv[1:5]
print(json.dumps({"timestamp": ts, "level": lvl, "message": msg, "context": ctx}))
PY
    fi
}

cbw_log_event() {
    local level="${1:-INFO}"
    shift
    local message="$1"
    shift
    local context="$*"
    local payload
    payload="$(_cbw_obs_payload "$level" "$message" "$context")" || return 1

    mkdir -p "${CBW_OBS_ROOT:-$HOME/logs/observability}"
    : "${CBW_OBS_LOG:=$CBW_OBS_ROOT/events.log}"
    printf '%s\n' "$payload" >> "$CBW_OBS_LOG"

    if [[ -n "$CBW_OTEL_HTTP_COLLECTOR" ]]; then
        curl -s --max-time 3 -X POST "$CBW_OTEL_HTTP_COLLECTOR/v1/logs" \
            -H "Content-Type: application/json" \
            -d "$payload" >/dev/null 2>&1 || true
    fi

    if [[ -n "$CBW_LOKI_PUSH_URL" ]] && command -v jq >/dev/null 2>&1; then
        local loki_payload
        loki_payload=$(jq -n \
            --arg time "$(date +%s%N)" \
            --argjson event "$payload" \
            '{streams:[{stream:{app:"cbw-shell"},values:[[$time,($event|tostring)]]}]}')
        curl -s --max-time 3 -X POST "$CBW_LOKI_PUSH_URL" \
            -H "Content-Type: application/json" \
            -d "$loki_payload" >/dev/null 2>&1 || true
    fi
}

cbw_log_metric() {
    local name="$1"; shift
    local value="$1"; shift
    local labels="${*:-}"
    local ts
    ts=$(_cbw_obs_timestamp)
    : "${CBW_OBS_METRICS:=$CBW_OBS_ROOT/metrics.prom}"
    mkdir -p "$(dirname "$CBW_OBS_METRICS")"
    printf '# %s %s\n%s{%s} %s %s\n' "$ts" "$name" "$name" "${labels:-source=\"shell\"}" "$value" "$(date +%s)" >> "$CBW_OBS_METRICS"
}

cbw_trace_span() {
    local name="$1"; shift
    local status="${1:-OK}"
    local context="$*"
    cbw_log_event "TRACE" "$name" "status=$status $context"
}

cbw_observe_command() {
    local label="$1"; shift
    local start end duration rc
    start=$(date +%s%3N)
    "$@"
    rc=$?
    end=$(date +%s%3N)
    duration=$((end - start))
    cbw_log_event "INFO" "$label" "duration_ms=$duration exit_code=$rc cmd=$*"
    cbw_log_metric "cbw_command_duration_ms" "$duration" "command=\"$label\""
    return $rc
}

alias obslog='cbw_log_event'
alias obsdur='cbw_observe_command'
