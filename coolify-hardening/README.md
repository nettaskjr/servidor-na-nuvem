# Coolify Hardening & Operations Kit

Conjunto de scripts e configs para hardening, backup, monitoramento e DR do Coolify em produção.

## 📁 Estrutura

```
coolify-hardening/
├── ufw-setup.sh           # Firewall host (UFW)
├── fail2ban-setup.sh      # Fail2Ban (SSH + Traefik)
├── ssh-hardening.sh       # SSH hardening
├── coolify-backup.sh      # Backup DB + Data (diário + off-site)
├── coolify-logrotate      # Log rotation Docker
├── docker-compose.yml     # Coolify stack com resource limits
├── coolify-healthcheck.sh # Health check + alerta
├── dr-test.sh             # Disaster Recovery test
└── README.md              # Este arquivo
```

## 🚀 Instalação Rápida (Ordem Recomendada)

```bash
cd /home/nestor/projetos/servidor-na-nuvem/coolify-hardening

# 1. Firewall (UFW)
sudo bash ufw-setup.sh

# 2. Fail2Ban
sudo bash fail2ban-setup.sh

# 3. SSH Hardening (TESTE EM OUTRA JANELA PRIMEIRO!)
sudo bash ssh-hardening.sh

# 4. Logrotate
sudo cp coolify-logrotate /etc/logrotate.d/coolify

# 5. Backup - instalar script e cron
sudo cp coolify-backup.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/coolify-backup.sh
echo "0 3 * * * root /usr/local/bin/coolify-backup.sh --offsite" | sudo tee /etc/cron.d/coolify-backup

# 6. Docker Compose com limits (FAÇA BACKUP DO ORIGINAL PRIMEIRO!)
cp /data/coolify/docker-compose.yml /data/coolify/docker-compose.yml.backup
# Edite docker-compose.yml com seus valores reais (domínio, senhas, tokens)
# cp docker-compose.yml /data/coolify/docker-compose.yml
# docker compose -f /data/coolify/docker-compose.yml up -d

# 7. Health check cron (a cada 5 min)
sudo cp coolify-healthcheck.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/coolify-healthcheck.sh
echo "*/5 * * * * root /usr/local/bin/coolify-healthcheck.sh --webhook-url=https://seu-webhook --email=seu@email.com" | sudo tee /etc/cron.d/coolify-healthcheck

# 8. DR Test (rode mensalmente em staging)
# sudo bash dr-test.sh
```

## ⚙️ Configurações Necessárias (Edite Antes de Usar)

| Arquivo                    | O que editar                                                                                   |
| -------------------------- | ---------------------------------------------------------------------------------------------- |
| `docker-compose.yml`     | `APP_URL`, `SECRET_KEY`, `DB_PASSWORD`, `REDIS_PASSWORD`, `CF_DNS_API_TOKEN`, emails |
| `coolify-backup.sh`      | `BACKUP_DIR`, `RETENTION_DAYS`, configure `rclone` para off-site                         |
| `coolify-healthcheck.sh` | `COOLIFY_URL`, `WEBHOOK_URL`, `EMAIL`                                                    |
| `fail2ban-setup.sh`      | Se usar Cloudflare action: configure`cloudflare-api.conf` com email, API key, zone ID        |
| `ssh-hardening.sh`       | `AllowUsers` (seu usuário), `Port` (se mudar)                                             |

## 🔐 Segredos - NÃO COMMITE VALORES REAIS

Use uma das abordagens:

```bash
# Opção 1: .env file (não versionar)
cat > /data/coolify/.env <<'EOF'
DB_PASSWORD=senha_super_secreta
REDIS_PASSWORD=outra_senha_secreta
SECRET_KEY=$(openssl rand -hex 32)
CF_DNS_API_TOKEN=seu_token_cloudflare
EOF

# Opção 2: Docker Secrets (Swarm)
echo "senha_super_secreta" | docker secret create coolify_db_password -

# Opção 3: 1Password CLI
op read "op://Vault/Coolify/db_password" --format=raw
```

## 📋 Checklist Pós-Instalação

- [ ] UFW ativo com 22 desabilitado, 80/443 habilitados
- [ ] Fail2Ban rodando (sshd, traefik-auth, traefik-4xx)
- [ ] SSH hardening aplicado + testado em nova janela
- [ ] Logrotate instalado em `/etc/logrotate.d/coolify`
- [ ] Backup rodando diário (verifique `/backups/coolify/`)
- [ ] Off-site backup configurado (rclone + S3/GCS/B2)
- [ ] Docker Compose com resource limits aplicado
- [ ] Health check cron ativo + alertando (Discord/Slack/Email)
- [ ] DR test executado com sucesso nos últimos 30 dias
- [ ] Instance Domain = `https://coolify.seu-dominio.com` (HTTPS!)
- [ ] MFA (2FA) habilitado no perfil Coolify
- [ ] API Token guardado no True Key / 1Password / Bitwarden

## 🛠️ Comandos Úteis Diários

```bash
# Ver logs Coolify
docker logs -f coolify

# Ver stats de recursos
docker stats

# Ver backups
ls -lh /backups/coolify/

# Testar backup manual
/usr/local/bin/coolify-backup.sh --offsite

# Ver IPs banidos
fail2ban-client status sshd
fail2ban-client status traefik-auth

# Desbanir IP
fail2ban-client set sshd unbanip 1.2.3.4

# Abrir SSH temporário
sudo ufw allow 22/tcp
# ...fazer o que precisa...
sudo ufw delete allow 22/tcp

# Health check manual
/usr/local/bin/coolify-healthcheck.sh

# DR test (em staging!)
/usr/local/bin/dr-test.sh
```

## 🔄 Atualizações

```bash
# Coolify
docker pull coolify/coolify:latest
docker compose -f /data/coolify/docker-compose.yml up -d coolify

# Traefik
docker pull traefik:v3.0
docker compose -f /data/coolify/docker-compose.yml up -d traefik

# Sistema
apt update && apt upgrade -y
# Reboot se kernel atualizado
```

## 📞 Suporte / Referências

- Coolify Docs: https://coolify.io/docs
- Traefik Docs: https://doc.traefik.io/traefik/
- Fail2Ban: https://www.fail2ban.org/wiki/index.php/Main_Page
- UFW: https://help.ubuntu.com/community/UFW
- Cloudflare Tunnel: https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
