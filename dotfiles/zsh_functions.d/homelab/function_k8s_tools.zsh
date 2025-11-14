#!/bin/zsh

# =============================================================================
# KUBERNETES TOOLS (HOMELAB)
# =============================================================================
# Kubernetes cluster management utilities
# =============================================================================

# Get all pods in all namespaces
k8s_all_pods() {
    kubectl get pods --all-namespaces -o wide
}

# Get node status
k8s_nodes() {
    kubectl get nodes -o wide
}

# Watch pod status in real-time
k8s_watch() {
    local namespace="${1:-default}"
    watch kubectl get pods -n "$namespace" -o wide
}

# Get pod logs
k8s_logs() {
    local pod="$1"
    local namespace="${2:-default}"
    kubectl logs -n "$namespace" -f "$pod"
}

# Port forward to a service
k8s_portforward() {
    local service="$1"
    local local_port="$2"
    local remote_port="${3:-$local_port}"
    local namespace="${4:-default}"
    
    kubectl port-forward -n "$namespace" "service/$service" "$local_port:$remote_port"
}

# Describe resource
k8s_describe() {
    local resource="$1"
    local name="$2"
    local namespace="${3:-default}"
    kubectl describe -n "$namespace" "$resource" "$name"
}