#!/usr/bin/env bash
#
# Consulta a disponibilidade de capacidade de um shape de compute na OCI.
#
# Existe porque os shapes do sempre-gratuito (A1.Flex, E2.1.Micro) vivem
# esgotados em sa-saopaulo-1. Rodar periodicamente para detectar quando abrem.
#
# Uso:
#   ./scripts/check_capacity.sh                    # A1.Flex 4 OCPU / 24 GB
#   ./scripts/check_capacity.sh VM.Standard.E5.Flex 1 8
#
# Saída: 0 se AVAILABLE, 1 caso contrário — encadeável em cron ou watch.

set -euo pipefail

SHAPE="${1:-VM.Standard.A1.Flex}"
OCPUS="${2:-4}"
MEMORY_GB="${3:-24}"

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/local/oci.env"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

: "${OCI_COMPARTMENT_ID:?defina OCI_COMPARTMENT_ID ou crie local/oci.env}"
: "${OCI_AD:?defina OCI_AD ou crie local/oci.env}"

export SUPPRESS_LABEL_WARNING=True

# Shapes fixos (não-Flex) não aceitam instanceShapeConfig.
if [[ "$SHAPE" == *".Flex" ]]; then
    payload="[{\"instanceShape\":\"$SHAPE\",\"instanceShapeConfig\":{\"ocpus\":$OCPUS,\"memoryInGBs\":$MEMORY_GB}}]"
    label="$SHAPE ($OCPUS OCPU / ${MEMORY_GB}GB)"
else
    payload="[{\"instanceShape\":\"$SHAPE\"}]"
    label="$SHAPE"
fi

status=$(oci compute compute-capacity-report create \
    --compartment-id "$OCI_COMPARTMENT_ID" \
    --availability-domain "$OCI_AD" \
    --shape-availabilities "$payload" \
    --query 'data."shape-availabilities"[0]."availability-status"' \
    --raw-output 2>/dev/null || echo "ERRO_NA_CONSULTA")

printf '%s  %-45s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$label" "$status"

if [ "$status" = "AVAILABLE" ]; then
    if command -v osascript >/dev/null 2>&1; then
        osascript -e "display notification \"$label liberado em $OCI_AD\" with title \"Capacidade OCI\"" 2>/dev/null || true
    fi
    exit 0
fi

exit 1
