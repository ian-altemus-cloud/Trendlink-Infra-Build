#!/usr/bin/env bash
set -eou pipefail

log_group="$1"
lockback_ms=86400000  # 1 day in milliseconds

start_time=$(( $(date +%s) * 1000 - lockback_ms ))

error_count=$(aws logs filter-log-events \
    --profile tv-dev --region us-east-1 \
    --log-group-name "$log_group" \
    --start-time "$start_time" \
    --filter-pattern '"ERROR"' \
    --query 'length(events)' \
    --output text)

    if [[ "$error_count" -gt 0 ]]; then
        echo "Found $error_count ERROR logs in log group $log_group in the last 24 hours."
        exit 1
    else
        echo "No ERROR logs found in log group $log_group in the last 24 hours."
        exit 0
    fi

    echo "No errors found in log_group"
    exit 0