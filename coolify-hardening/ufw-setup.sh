#!/usr/bin/env bash
# UFW Firewall Setup para servidor com Cloudflare Tunnel
# Execute como root: sudo bash ufw-setup.sh

set -euo pipefail

echo "=== Configurando UFW ==="

# Reset para estado limpo (cuidado se já tiver regras importantes)
# ufw --force reset

# Políticas padrão
ufw default deny incoming
ufw default allow outgoing

# SSH - regra existe mas DESABILITADA por padrão
# Para habilitar temporariamente: sudo ufw allow 22/tcp
# Para desabilitar: sudo ufw delete allow 22/tcp
ufw allow 22/tcp comment 'SSH admin (habilitar só quando necessário)'
ufw disable 22/tcp 2>/dev/null || true  # garante que começa desabilitado

# HTTP/HTTPS - fallback se Cloudflare Tunnel cair
ufw allow 80/tcp comment 'HTTP fallback (Cloudflare Tunnel)'
ufw allow 443/tcp comment 'HTTPS fallback (Cloudflare Tunnel)'

# Docker - se usa docker em host network, pode precisar
# ufw allow 2376/tcp comment 'Docker daemon (se necessário)'

# Habilita UFW
ufw --force enable

echo "=== Status UFW ==="
ufw status numbered verbose

echo ""
echo "COMANDOS ÚTEIS:"
echo "  Abrir SSH temporário:    sudo ufw allow 22/tcp"
echo "  Fechar SSH:              sudo ufw delete allow 22/tcp"
echo "  Ver regras:              sudo ufw status numbered"
echo "  Desabilitar UFW:         sudo ufw disable"
echo "  Reabilitar UFW:          sudo ufw enable"