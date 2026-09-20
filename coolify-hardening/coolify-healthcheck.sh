#!/usr/bin/env bash
# Coolify Health Check + Alert Script
# Uso: coolify-healthcheck.sh [--webhook-url=URL] [--email=EMAIL]

set -euo pipefail

COOLIFY_URL="https://coolify.seu-dominio.com"  # AJUSTE
HEALTH_ENDPOINT="/api/health"
WEBHOOK_URL=""
EMAIL=""
TIMEOUT=10

for arg in "$@"; do
    case $arg in
        --webhook-url=*) WEBHOOK_URL="${arg#*=}" ;;
        --email=*) EMAIL="${arg#*=}" ;;
        --url=*) COOLIFY_URL="${arg#*=}" ;;
        *) echo "Uso: $0 [--webhook-url=URL] [--email=EMAIL] [--url=COOLIFY_URL]" ; exit 1 ;;
    esac
done

alert() {
    local subject="$1" message="$2"
    if [[ -n "$WEBHOOK_URL" ]]; then
        curl -s -X POST "$WEBHOOK_URL" \
            -H "Content-Type: application/json" \
            -d "{\"text\":\"$subject\n$message\"}" >/dev/null || true
    fi
    if [[ -n "$EMAIL" ]] && command -v mail >/dev/null 2>&1; then
        echo "$message" | mail -s "$subject" "$EMAIL" || true
    fi
    logger -t coolify-healthcheck "$subject: $message"
}

# Health check
response=$(curl -sf --max-time "$TIMEOUT" "$COOLIFY_URL$HEALTH_ENDPOINT" 2>/dev/null || echo "FAILED")
http_code=$(curl -s -o /dev/null -w "%{http_code}" --max-time "$TIMEOUT" "$COOLIFY_URL$HEALTH_ENDPOINT" 2>/dev/null || echo "000")

if [[ "$http_code" == "200" ]] && echo "$response" | grep -q '"status":"ok"'; then
    echo "✅ Coolify saudável (HTTP $http_code)"
    exit 0
else
    msg="Coolify health check falhou: HTTP $http_code, Response: $response"
    echo "❌ $msg"
    alert "🚨 ALERTA: Coolify DOWN" "$msg\n\nURL: $COOLIFY_URL$HEALTH_ENDPOINT\nHorário: $(date)\nHost: $(hostname)"
    exit 1
fi