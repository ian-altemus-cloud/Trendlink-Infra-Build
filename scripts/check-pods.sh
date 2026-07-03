#!/usr/bin/env bash
set -euo pipefail

bad_pods=0

while read -r pod_name pod_status; do
  if [[ "$pod_status" != "Running" && "$pod_status" != "Succeeded" ]]; then
    echo "Pod $pod_name is not healthy (status: $pod_status)"
    bad_pods=1

  fi
done < <(kubectl get pods -n default -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.phase}{"\n"}{end}')

if [[ "$bad_pods" -eq 1 ]]; then
  exit 1
fi

echo "All pods healthy"
exit 0