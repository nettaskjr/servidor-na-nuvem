#!/usr/bin/env bash
# Coolify Disaster Recovery Test Script
# TESTA restauração de backup em ambiente isolado
# ATENÇÃO: Para produção, use um servidor de staging separado!

set -euo pipefail

BACKUP_DIR="/backups/coolify"
TEST_DIR="/tmp/coolify-dr-test-$(date +%s)"
DB_TEST_CONTAINER="coolify-db-dr-test"
COOLIFY_TEST_CONTAINER="coolify-dr-test"

log() { echo "[$(date +'%F %T')] $*"; }

# Encontra backup mais recente
LATEST_DB=$(ls -t "$BACKUP_DIR"/coolify-db-*.sql.gz 2>/dev/null | head -1)
LATEST_DATA=$(ls -t "$BACKUP_DIR"/coolify-data-*.tar.gz 2>/dev/null | head -1)

if [[ -z "$LATEST_DB" || -z "$LATEST_DATA" ]]; then
    log "ERRO: Nenhum backup encontrado em $BACKUP_DIR"
    exit 1
fi

log "=== DR Test - Usando backups ==="
log "  DB: $LATEST_DB"
log "  Data: $LATEST_DATA"

# Cria diretório de teste
mkdir -p "$TEST_DIR/data"

# 1. Restaura DB em container temporário
log "Subindo PostgreSQL de teste..."
docker run -d --name "$DB_TEST_CONTAINER" \
    -e POSTGRES_DB=coolify \
    -e POSTGRES_USER=coolify \
    -e POSTGRES_PASSWORD=test123 \
    -p 5433:5432 \
    postgres:16-alpine

sleep 5

log "Restaurando database..."
gunzip -c "$LATEST_DB" | docker exec -i "$DB_TEST_CONTAINER" psql -U coolify coolify

# 2. Restaura data volume
log "Extraindo volume de dados..."
tar -xzf "$LATEST_DATA" -C "$TEST_DIR"

# 3. Sobe Coolify de teste (porta diferente)
log "Subindo Coolify de teste na porta 8001..."
docker run -d --name "$COOLIFY_TEST_CONTAINER" \
    --network host \
    -e APP_URL=http://localhost:8001 \
    -e DB_HOST=localhost \
    -e DB_PORT=5433 \
    -e DB_DATABASE=coolify \
    -e DB_USERNAME=coolify \
    -e DB_PASSWORD=test123 \
    -e REDIS_HOST=localhost \
    -e REDIS_PORT=6379 \
    -v "$TEST_DIR/data/coolify:/data/coolify" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    coolify/coolify:latest

sleep 15

# 4. Testa health check
log "Testando health endpoint..."
for i in {1..10}; do
    if curl -sf http://localhost:8001/api/health | grep -q '"status":"ok"'; then
        log "✅ DR TEST PASSOU - Coolify restaurado com sucesso!"
        break
    fi
    sleep 3
done

# 5. Cleanup
log "Limpando ambiente de teste..."
docker stop "$COOLIFY_TEST_CONTAINER" "$DB_TEST_CONTAINER" >/dev/null 2>&1
docker rm "$COOLIFY_TEST_CONTAINER" "$DB_TEST_CONTAINER" >/dev/null 2>&1
rm -rf "$TEST_DIR"

log "=== DR Test Concluído ==="