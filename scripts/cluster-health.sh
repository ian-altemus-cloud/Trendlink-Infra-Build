#!/usr/bin/env bash
set -euo pipefail

namespace="${1:-default}"

echo "=== Pod Status: $namespace==="
kubectl get pods -n "$namespace" -o wide

echo ""
echo "=== Resource Usage: $namespace==="
kubectl top pods -n "$namespace"