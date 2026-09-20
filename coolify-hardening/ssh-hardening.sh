#!/usr/bin/env bash
# SSH Hardening para servidor Coolify
# Execute como root: sudo bash ssh-hardening.sh

set -euo pipefail

SSHD_CONFIG="/etc/ssh/sshd_config"
BACKUP="${SSHD_CONFIG}.backup.$(date +%F_%H-%M)"

echo "=== Backup da configuração original ==="
cp "$SSHD_CONFIG" "$BACKUP"
echo "Backup salvo em: $BACKUP"

echo "=== Aplicando hardening ==="

# Função para definir/atualizar parâmetro
set_ssh_param() {
    local key="$1" value="$2"
    if grep -qE "^\s*${key}\s+" "$SSHD_CONFIG"; then
        sed -i "s/^\s*${key}\s\+.*/${key} ${value}/" "$SSHD_CONFIG"
    else
        echo "${key} ${value}" >> "$SSHD_CONFIG"
    fi
}

# Hardening settings
set_ssh_param "PermitRootLogin" "no"
set_ssh_param "PasswordAuthentication" "no"
set_ssh_param "PubkeyAuthentication" "yes"
set_ssh_param "AuthenticationMethods" "publickey"
set_ssh_param "PermitEmptyPasswords" "no"
set_ssh_param "ChallengeResponseAuthentication" "no"
set_ssh_param "UsePAM" "yes"
set_ssh_param "X11Forwarding" "no"
set_ssh_param "AllowAgentForwarding" "no"
set_ssh_param "AllowTcpForwarding" "no"
set_ssh_param "PermitTunnel" "no"
set_ssh_param "DebianBanner" "no"
set_ssh_param "PrintMotd" "no"
set_ssh_param "ClientAliveInterval" "300"
set_ssh_param "ClientAliveCountMax" "2"
set_ssh_param "MaxAuthTries" "3"
set_ssh_param "MaxSessions" "2"
set_ssh_param "LoginGraceTime" "30"
set_ssh_param "Banner" "/etc/ssh/banner"

# Porta não-padrão (opcional - descomente se quiser)
# set_ssh_param "Port" "2222"

# Restringir usuários (ajuste para seu usuário)
# set_ssh_param "AllowUsers" "seu_usuario"

# Criptografia moderna
cat >> "$SSHD_CONFIG" <<'EOF'

# === Crypto hardening (adicionado pelo script) ===
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-128-etm@openssh.com
HostKeyAlgorithms ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-256
EOF

# Banner de aviso legal
cat > /etc/ssh/banner <<'EOF'
***************************************************************************
*                    ACESSO RESTRITO - SERVIDOR PRIVADO                   *
*                                                                       *
*  Este sistema é para uso autorizado apenas. Todas as atividades       *
*  são monitoradas e registradas. Acesso não autorizado é proibido      *
*  e será processado conforme a lei.                                    *
***************************************************************************
EOF

echo "=== Testando configuração ==="
sshd -t

echo "=== Recarregando SSH ==="
systemctl reload ssh

echo "=== Status ==="
systemctl status ssh --no-pager -l

echo ""
echo "IMPORTANTE:"
echo "  - Teste a conexão em OUTRA janela ANTES de fechar esta!"
echo "  - Se usa porta customizada (ex: 2222), abra no UFW: sudo ufw allow 2222/tcp"
echo "  - Para reverter: cp $BACKUP $SSHD_CONFIG && systemctl reload ssh"