#!/usr/bin/env bash
# Coolify Backup Script - Database + Data Volume
# Execute como root ou usuário com acesso ao docker
# Uso: coolify-backup.sh [--offsite]

set -euo pipefail

BACKUP_DIR="/backups/coolify"
DATE=$(date +%F_%H-%M)
RETENTION_DAYS=7
OFFSITE=false

# Parse args
for arg in "$@"; do
    case $arg in
        --offsite) OFFSITE=true ;;
        --retention=*) RETENTION_DAYS="${arg#*=}" ;;
        *) echo "Uso: $0 [--offsite] [--retention=N]" ; exit 1 ;;
    esac
done

mkdir -p "$BACKUP_DIR"

log() { echo "[$(date +'%F %T')] $*"; }

log "=== Iniciando backup Coolify ==="

# 1. Verifica containers
if ! docker ps --format '{{.Names}}' | grep -q '^coolify-db$'; then
    log "ERRO: Container coolify-db não está rodando"
    exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q '^coolify$'; then
    log "AVISO: Container coolify não está rodando (backup de dados prossegue)"
fi

# 2. Backup Database (PostgreSQL)
DB_FILE="${BACKUP_DIR}/coolify-db-${DATE}.sql.gz"
log "Backup do banco de dados -> $DB_FILE"
docker exec coolify-db pg_dump -U coolify coolify | gzip > "$DB_FILE"
log "  Tamanho: $(du -h "$DB_FILE" | cut -f1)"

# 3. Backup Data Volume (/data/coolify)
DATA_FILE="${BACKUP_DIR}/coolify-data-${DATE}.tar.gz"
log "Backup do volume de dados -> $DATA_FILE"
tar -czf "$DATA_FILE" -C / data/coolify 2>/dev/null || {
    log "AVISO: /data/coolify não encontrado, tentando /var/lib/docker/volumes/coolify_data"
    tar -czf "$DATA_FILE" -C / var/lib/docker/volumes/coolify_data 2>/dev/null || {
        log "ERRO: Não encontrou volume de dados do Coolify"
        exit 1
    }
}
log "  Tamanho: $(du -h "$DATA_FILE" | cut -f1)"

# 4. Retenção local
log "Aplicando retenção local (${RETENTION_DAYS} dias)..."
find "$BACKUP_DIR" -name 'coolify-*' -mtime +"$RETENTION_DAYS" -delete
REMAINING=$(find "$BACKUP_DIR" -name 'coolify-*' | wc -l)
log "  Backups mantidos: $REMAINING"

# 5. Off-site (opcional - requer rclone configurado)
if $OFFSITE; then
    if command -v rclone >/dev/null 2>&1; then
        log "Enviando para storage remoto (rclone)..."
        rclone copy "$BACKUP_DIR" remote:coolify-backups/ \
            --include "coolify-*${DATE}*" \
            --progress
        log "  Upload concluído"
    else
        log "AVISO: rclone não instalado, pulando off-site"
    fi
fi

# 6. Verificação rápida de integridade
log "Verificando integridade..."
gunzip -t "$DB_FILE" && log "  DB OK" || log "  DB CORROMPIDO!"
tar -tzf "$DATA_FILE" >/dev/null && log "  Data OK" || log "  Data CORROMPIDO!"

log "=== Backup concluído com sucesso ==="
echo ""
echo "Arquivos criados:"
ls -lh "$BACKUP_DIR"/coolify-*${DATE}*