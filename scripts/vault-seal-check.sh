#!/usr/bin/env bash
set -euo pipefail

sealed=$(kubectl exec -n vault vault-0 -- vault status -format=json | jq -r '.sealed')

if [[ "$sealed" == "true" ]]; then
  echo "Vault is sealed"
  exit 1
fi

echo "Vault is unsealed"
exit 0