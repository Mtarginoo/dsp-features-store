#!/usr/bin/env bash
#
# Mostra o gasto acumulado do mês na tenancy, sem abrir o console.
#
# Usa o perfil DEFAULT (admin) de propósito: custos e orçamentos vivem na raiz
# da tenancy, fora do alcance da policy do dsp-devs. Alargar a policy só para
# isto enfraqueceria a fronteira sem necessidade.
#
# NÃO mostra saldo de créditos do trial — esse número só existe no console,
# em Billing & Cost Management. Nenhuma API pública da OCI o expõe.
#
# Uso: ./scripts/check_cost.sh

set -euo pipefail

ENV_FILE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/local/oci.env"
[ -f "$ENV_FILE" ] && source "$ENV_FILE"

: "${OCI_TENANCY_ID:?defina OCI_TENANCY_ID ou crie local/oci.env}"

export SUPPRESS_LABEL_WARNING=True

month_start=$(date -u +%Y-%m-01T00:00:00Z)
if date -u -v+1d >/dev/null 2>&1; then
    tomorrow=$(date -u -v+1d +%Y-%m-%dT00:00:00Z)   # BSD/macOS
else
    tomorrow=$(date -u -d '+1 day' +%Y-%m-%dT00:00:00Z)  # GNU
fi

echo "Período: $month_start até $tomorrow"
echo

if [ -n "${OCI_BUDGET_ID:-}" ]; then
    echo "── Orçamento ──"
    oci --profile DEFAULT budgets budget budget get --budget-id "$OCI_BUDGET_ID" \
        --query 'data.{limite:amount,gasto:"actual-spend",previsto:"forecasted-spend",atualizado:"time-spend-computed"}' \
        --output table 2>/dev/null | grep -v '^etag:' || echo "  falha ao consultar"
    echo
fi

echo "── Custo por serviço ──"
items=$(oci --profile DEFAULT usage-api usage-summary request-summarized-usages \
    --tenant-id "$OCI_TENANCY_ID" \
    --time-usage-started "$month_start" --time-usage-ended "$tomorrow" \
    --granularity MONTHLY --query-type COST --group-by '["service"]' \
    --query 'data.items[?"computed-amount"!=null].{servico:service,custo:"computed-amount",moeda:currency}' \
    --output table 2>/dev/null || true)

if [ -z "$items" ] || echo "$items" | grep -q 'no table'; then
    echo "  Nenhum custo registrado no período."
else
    echo "$items"
fi

echo
echo "Saldo de créditos do trial: apenas no console"
echo "  Billing & Cost Management > Cost Management > Subscriptions"
