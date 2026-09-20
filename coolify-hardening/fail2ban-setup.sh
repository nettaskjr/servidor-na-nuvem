#!/usr/bin/env bash
# Fail2Ban Setup para Coolify + Cloudflare Tunnel
# Execute como root: sudo bash fail2ban-setup.sh

set -euo pipefail

echo "=== Instalando Fail2Ban ==="
apt-get update && apt-get install -y fail2ban

echo "=== Criando configurações locais ==="

# 1. SSH Jail (mesmo com porta fechada, protege quando aberta)
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled  = true
port     = 22
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 24h
findtime = 10m
backend  = systemd
EOF

# 2. Traefik Auth Jail (protege painel Coolify, APIs, etc.)
cat > /etc/fail2ban/jail.d/traefik-auth.local <<'EOF'
[traefik-auth]
enabled  = true
filter   = traefik-auth
logpath  = /var/lib/docker/containers/*/*-json.log
maxretry = 5
bantime  = 1h
findtime = 10m
backend  = auto
# Action padrão = iptables-multiport (bloqueia no host)
# Para bloquear na Cloudflare (melhor), use action = cloudflare-api e configure abaixo
EOF

# 3. Traefik Rate Limit / 4xx Jail (protege contra scans, bots)
cat > /etc/fail2ban/jail.d/traefik-4xx.local <<'EOF'
[traefik-4xx]
enabled  = true
filter   = traefik-4xx
logpath  = /var/lib/docker/containers/*/*-json.log
maxretry = 20
bantime  = 30m
findtime = 5m
backend  = auto
EOF

# 4. Filtro personalizado para Traefik (auth failures)
cat > /etc/fail2ban/filter.d/traefik-auth.conf <<'EOF'
[Definition]
# Traefik access log JSON lines com status 401, 403
# Ex: {"level":"info","msg":"","time":"2024-01-01T00:00:00Z","remote_addr":"1.2.3.4","status":401,...}
failregex = ^.*"remote_addr":"(<HOST>)".*"status":(401|403).*
ignoreregex =
EOF

# 5. Filtro para 4xx excessivos (scanners)
cat > /etc/fail2ban/filter.d/traefik-4xx.conf <<'EOF'
[Definition]
# Muitos 404/400/444 em pouco tempo = scanner
failregex = ^.*"remote_addr":"(<HOST>)".*"status":(400|404|444).*
ignoreregex =
EOF

# 6. (Opcional) Action Cloudflare - requer API Key Global e Zone ID
# Descomente e configure se quiser banir na edge da Cloudflare
# cat > /etc/fail2ban/action.d/cloudflare-api.conf <<'EOF'
# [Definition]
# actionban = curl -s -X POST "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/firewall/access_rules/rules" \
#      -H "X-Auth-Email: <EMAIL>" -H "X-Auth-Key: <GLOBAL_API_KEY>" \
#      -H "Content-Type: application/json" \
#      --data '{"mode":"block","configuration":{"target":"ip","value":"<ip>"},"notes":"Fail2Ban <name>"}'
# actionunban = curl -s -X DELETE "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/firewall/access_rules/rules/$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/<ZONE_ID>/firewall/access_rules/rules?configuration.target=ip&configuration.value=<ip>" -H "X-Auth-Email: <EMAIL>" -H "X-Auth-Key: <GLOBAL_API_KEY>" | jq -r '.result[0].id')" \
#      -H "X-Auth-Email: <EMAIL>" -H "X-Auth-Key: <GLOBAL_API_KEY>"
# EOF

echo "=== Reiniciando Fail2Ban ==="
systemctl enable --now fail2ban
systemctl restart fail2ban

echo "=== Status ==="
fail2ban-client status
echo ""
fail2ban-client status sshd
fail2ban-client status traefik-auth
fail2ban-client status traefik-4xx

echo ""
echo "COMANDOS ÚTEIS:"
echo "  Ver jails ativas:           fail2ban-client status"
echo "  Ver IPs banidos (sshd):     fail2ban-client status sshd"
echo "  Desbanir IP:                fail2ban-client set sshd unbanip 1.2.3.4"
echo "  Logs do fail2ban:           tail -f /var/log/fail2ban.log"
echo "  Testar filtro:              fail2ban-regex /var/log/auth.log /etc/fail2ban/filter.d/sshd.conf"