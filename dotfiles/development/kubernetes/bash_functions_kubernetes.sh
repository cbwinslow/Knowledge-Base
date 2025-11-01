#!/bin/bash
# Kubernetes Functions - Template
# Category: Container Orchestration
# Description: Functions for managing Kubernetes clusters and resources
# Usage: Source this file in your .bashrc or .zshrc
# Prerequisites: kubectl installed and configured
# Author: Knowledge Base Team
# Last Updated: 2025-11-01

# =============================================================================
# Pod Management
# =============================================================================

# Function: k8s_get_pods
# Description: Get all pods in current namespace
# Usage: k8s_get_pods [namespace]
# Arguments:
#   $1 - Optional namespace (default: current)
# Returns: List of pods
# Example: k8s_get_pods default
k8s_get_pods() {
    if [[ $# -gt 0 ]]; then
        kubectl get pods -n "$1"
    else
        kubectl get pods
    fi
}

# Function: k8s_describe_pod
# Description: Describe a specific pod
# Usage: k8s_describe_pod <pod_name> [namespace]
# Arguments:
#   $1 - Pod name
#   $2 - Optional namespace
# Returns: Pod details
# Example: k8s_describe_pod mypod-123 default
k8s_describe_pod() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Pod name required"
        echo "Usage: k8s_describe_pod <pod_name> [namespace]"
        return 1
    fi
    
    local pod_name="$1"
    local namespace="${2:-}"
    
    if [[ -n "$namespace" ]]; then
        kubectl describe pod "$pod_name" -n "$namespace"
    else
        kubectl describe pod "$pod_name"
    fi
}

# Function: k8s_delete_pod
# Description: Delete a specific pod
# Usage: k8s_delete_pod <pod_name> [namespace]
# Arguments:
#   $1 - Pod name
#   $2 - Optional namespace
# Returns: 0 on success
# Example: k8s_delete_pod mypod-123 default
k8s_delete_pod() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Pod name required"
        echo "Usage: k8s_delete_pod <pod_name> [namespace]"
        return 1
    fi
    
    local pod_name="$1"
    local namespace="${2:-}"
    
    if [[ -n "$namespace" ]]; then
        kubectl delete pod "$pod_name" -n "$namespace"
    else
        kubectl delete pod "$pod_name"
    fi
}

# Function: k8s_logs
# Description: Get logs from a pod
# Usage: k8s_logs <pod_name> [namespace] [container]
# Arguments:
#   $1 - Pod name
#   $2 - Optional namespace
#   $3 - Optional container name (for multi-container pods)
# Returns: Pod logs
# Example: k8s_logs mypod-123 default mycontainer
k8s_logs() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Pod name required"
        echo "Usage: k8s_logs <pod_name> [namespace] [container]"
        return 1
    fi
    
    local pod_name="$1"
    local namespace="${2:-}"
    local container="${3:-}"
    
    local cmd="kubectl logs -f $pod_name"
    
    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi
    
    if [[ -n "$container" ]]; then
        cmd="$cmd -c $container"
    fi
    
    eval "$cmd"
}

# Function: k8s_exec_bash
# Description: Execute bash in a pod
# Usage: k8s_exec_bash <pod_name> [namespace] [container]
# Arguments:
#   $1 - Pod name
#   $2 - Optional namespace
#   $3 - Optional container name
# Returns: Interactive bash session
# Example: k8s_exec_bash mypod-123 default
k8s_exec_bash() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Pod name required"
        echo "Usage: k8s_exec_bash <pod_name> [namespace] [container]"
        return 1
    fi
    
    local pod_name="$1"
    local namespace="${2:-}"
    local container="${3:-}"
    
    local cmd="kubectl exec -it $pod_name"
    
    if [[ -n "$namespace" ]]; then
        cmd="$cmd -n $namespace"
    fi
    
    if [[ -n "$container" ]]; then
        cmd="$cmd -c $container"
    fi
    
    cmd="$cmd -- /bin/bash"
    
    eval "$cmd"
}

# =============================================================================
# Deployment Management
# =============================================================================

# Function: k8s_get_deployments
# Description: Get all deployments in namespace
# Usage: k8s_get_deployments [namespace]
# Arguments:
#   $1 - Optional namespace
# Returns: List of deployments
k8s_get_deployments() {
    if [[ $# -gt 0 ]]; then
        kubectl get deployments -n "$1"
    else
        kubectl get deployments
    fi
}

# Function: k8s_restart_deployment
# Description: Restart a deployment
# Usage: k8s_restart_deployment <deployment_name> [namespace]
# Arguments:
#   $1 - Deployment name
#   $2 - Optional namespace
# Returns: 0 on success
# Example: k8s_restart_deployment myapp default
k8s_restart_deployment() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Deployment name required"
        echo "Usage: k8s_restart_deployment <deployment_name> [namespace]"
        return 1
    fi
    
    local deployment="$1"
    local namespace="${2:-}"
    
    if [[ -n "$namespace" ]]; then
        kubectl rollout restart deployment "$deployment" -n "$namespace"
    else
        kubectl rollout restart deployment "$deployment"
    fi
}

# Function: k8s_scale_deployment
# Description: Scale a deployment to specified replicas
# Usage: k8s_scale_deployment <deployment_name> <replicas> [namespace]
# Arguments:
#   $1 - Deployment name
#   $2 - Number of replicas
#   $3 - Optional namespace
# Returns: 0 on success
# Example: k8s_scale_deployment myapp 3 default
k8s_scale_deployment() {
    if [[ $# -lt 2 ]]; then
        echo "Error: Deployment name and replica count required"
        echo "Usage: k8s_scale_deployment <deployment_name> <replicas> [namespace]"
        return 1
    fi
    
    local deployment="$1"
    local replicas="$2"
    local namespace="${3:-}"
    
    if [[ -n "$namespace" ]]; then
        kubectl scale deployment "$deployment" --replicas="$replicas" -n "$namespace"
    else
        kubectl scale deployment "$deployment" --replicas="$replicas"
    fi
}

# =============================================================================
# Service Management
# =============================================================================

# Function: k8s_get_services
# Description: Get all services in namespace
# Usage: k8s_get_services [namespace]
# Arguments:
#   $1 - Optional namespace
# Returns: List of services
k8s_get_services() {
    if [[ $# -gt 0 ]]; then
        kubectl get services -n "$1"
    else
        kubectl get services
    fi
}

# Function: k8s_port_forward
# Description: Forward a local port to a pod
# Usage: k8s_port_forward <pod_name> <local_port> <pod_port> [namespace]
# Arguments:
#   $1 - Pod name
#   $2 - Local port
#   $3 - Pod port
#   $4 - Optional namespace
# Returns: Port forwarding session
# Example: k8s_port_forward mypod 8080 80 default
k8s_port_forward() {
    if [[ $# -lt 3 ]]; then
        echo "Error: Pod name, local port, and pod port required"
        echo "Usage: k8s_port_forward <pod_name> <local_port> <pod_port> [namespace]"
        return 1
    fi
    
    local pod_name="$1"
    local local_port="$2"
    local pod_port="$3"
    local namespace="${4:-}"
    
    if [[ -n "$namespace" ]]; then
        kubectl port-forward "$pod_name" "$local_port:$pod_port" -n "$namespace"
    else
        kubectl port-forward "$pod_name" "$local_port:$pod_port"
    fi
}

# =============================================================================
# Namespace Management
# =============================================================================

# Function: k8s_get_namespaces
# Description: Get all namespaces
# Usage: k8s_get_namespaces
# Returns: List of namespaces
k8s_get_namespaces() {
    kubectl get namespaces
}

# Function: k8s_set_namespace
# Description: Set current context namespace
# Usage: k8s_set_namespace <namespace>
# Arguments:
#   $1 - Namespace name
# Returns: 0 on success
# Example: k8s_set_namespace production
k8s_set_namespace() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Namespace name required"
        echo "Usage: k8s_set_namespace <namespace>"
        return 1
    fi
    
    local namespace="$1"
    
    kubectl config set-context --current --namespace="$namespace"
}

# =============================================================================
# Context Management
# =============================================================================

# Function: k8s_get_contexts
# Description: Get all available contexts
# Usage: k8s_get_contexts
# Returns: List of contexts
k8s_get_contexts() {
    kubectl config get-contexts
}

# Function: k8s_use_context
# Description: Switch to a different context
# Usage: k8s_use_context <context_name>
# Arguments:
#   $1 - Context name
# Returns: 0 on success
# Example: k8s_use_context production-cluster
k8s_use_context() {
    if [[ $# -lt 1 ]]; then
        echo "Error: Context name required"
        echo "Usage: k8s_use_context <context_name>"
        return 1
    fi
    
    local context="$1"
    
    kubectl config use-context "$context"
}

# Function: k8s_current_context
# Description: Show current context
# Usage: k8s_current_context
# Returns: Current context name
k8s_current_context() {
    kubectl config current-context
}

# =============================================================================
# Resource Management
# =============================================================================

# Function: k8s_get_all
# Description: Get all resources in namespace
# Usage: k8s_get_all [namespace]
# Arguments:
#   $1 - Optional namespace
# Returns: All resources
k8s_get_all() {
    if [[ $# -gt 0 ]]; then
        kubectl get all -n "$1"
    else
        kubectl get all
    fi
}

# Function: k8s_delete_all_pods
# Description: Delete all pods in namespace (use with caution)
# Usage: k8s_delete_all_pods [namespace]
# Arguments:
#   $1 - Optional namespace
# Returns: 0 on success
k8s_delete_all_pods() {
    local namespace="${1:-default}"
    
    echo "WARNING: This will delete all pods in namespace: $namespace"
    read -p "Are you sure? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete pods --all -n "$namespace"
    else
        echo "Operation cancelled"
    fi
}

# =============================================================================
# ConfigMap and Secret Management
# =============================================================================

# Function: k8s_get_configmaps
# Description: Get all configmaps in namespace
# Usage: k8s_get_configmaps [namespace]
# Arguments:
#   $1 - Optional namespace
# Returns: List of configmaps
k8s_get_configmaps() {
    if [[ $# -gt 0 ]]; then
        kubectl get configmaps -n "$1"
    else
        kubectl get configmaps
    fi
}

# Function: k8s_get_secrets
# Description: Get all secrets in namespace
# Usage: k8s_get_secrets [namespace]
# Arguments:
#   $1 - Optional namespace
# Returns: List of secrets
k8s_get_secrets() {
    if [[ $# -gt 0 ]]; then
        kubectl get secrets -n "$1"
    else
        kubectl get secrets
    fi
}

# =============================================================================
# Utility Functions
# =============================================================================

# Function: k8s_top_nodes
# Description: Show node resource usage
# Usage: k8s_top_nodes
# Returns: Node resource metrics
k8s_top_nodes() {
    kubectl top nodes
}

# Function: k8s_top_pods
# Description: Show pod resource usage
# Usage: k8s_top_pods [namespace]
# Arguments:
#   $1 - Optional namespace
# Returns: Pod resource metrics
k8s_top_pods() {
    if [[ $# -gt 0 ]]; then
        kubectl top pods -n "$1"
    else
        kubectl top pods
    fi
}

# Function: k8s_events
# Description: Get events in namespace
# Usage: k8s_events [namespace]
# Arguments:
#   $1 - Optional namespace
# Returns: Recent events
k8s_events() {
    if [[ $# -gt 0 ]]; then
        kubectl get events -n "$1" --sort-by='.lastTimestamp'
    else
        kubectl get events --sort-by='.lastTimestamp'
    fi
}
