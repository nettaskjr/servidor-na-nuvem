#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="${ROOT_DIR}/terraform"

COR_CYAN='\033[0;36m'
COR_VERDE='\033[0;32m'
COR_AMARELA='\033[0;33m'
COR_VERMELHA='\033[0;31m'
COR_RESET='\033[0m'

info()  { printf "${COR_CYAN}%s${COR_RESET}\n" "$*"; }
ok()    { printf "${COR_VERDE}%s${COR_RESET}\n" "$*"; }
warn()  { printf "${COR_AMARELA}%s${COR_RESET}\n" "$*"; }
erro()  { printf "${COR_VERMELHA}%s${COR_RESET}\n" "$*" >&2; }

# Pede uma informação e guarda na variável informada ($2).
# ask "Pergunta" NOME_VARIAVEL [valor_padrao]
ask() {
  local pergunta="$1" var="$2" padrao="${3:-}"
  local extra=""
  if [[ -n "$padrao" ]]; then
    extra=" [${padrao}]"
  fi
  printf "${COR_AMARELA}?${COR_RESET} %s%s: " "$pergunta" "$extra"
  local resp
  read -r resp
  if [[ -z "$resp" && -n "$padrao" ]]; then
    resp="$padrao"
  fi
  printf -v "$var" '%s' "$resp"
}

# Pede um segredo (senha/token) sem exibir o valor digitado.
ask_secret() {
  local pergunta="$1" var="$2"
  printf "${COR_AMARELA}?${COR_RESET} %s: " "$pergunta"
  local resp
  read -rs resp
  printf "\n"
  printf -v "$var" '%s' "$resp"
}

# Escapa valores para uso dentro de strings HCL.
hcl_escape() {
  local s="$1"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

# Pede o caminho da chave pública SSH (comum a todas as clouds).
# Repete a pergunta até que um arquivo válido seja informado.
ask_ssh_key() {
  local chave
  while true; do
    ask "Caminho da chave pública SSH" chave "${HOME}/.ssh/id_rsa.pub"
    if [[ -f "$chave" ]]; then
      break
    fi
    erro "Chave pública não encontrada: $chave"
  done
  SSH_PUBLIC_KEY="$(<"$chave")"
}

# Garante que o diretório do provider existe e sobrescreve o tfvars.
prepare_dir() {
  local cloud="$1"
  local dir="${TERRAFORM_DIR}/${cloud}"
  mkdir -p "$dir"
  echo "$dir"
}

run_terraform() {
  local cloud="$1"
  local dir="${TERRAFORM_DIR}/${cloud}"
  info "Executando Terraform em ${dir}"
  ( cd "$dir"
    terraform init
    terraform validate
    terraform plan -out=tfplan
    ask "Aplicar as mudanças agora (S/n)" APLICAR "S"
    if [[ "$APLICAR" =~ ^[Ss]$ ]]; then
      terraform apply tfplan
    else
      warn "Plano gerado mas não aplicado. Execute: terraform apply ${dir}/tfplan"
    fi
  )
}

# Verifica se o terraform.tfvars da cloud já existe. Se existir, pergunta
# se o usuário quer usá-lo (inicia criação/atualização) ou gerar um novo
# (remove o arquivo e refaz as perguntas).
# Retorna 0 = usar existente | 1 = gerar novo.
check_existing_tfvars() {
  local cloud="$1"
  local tfvars="${TERRAFORM_DIR}/${cloud}/terraform.tfvars"

  if [[ -f "$tfvars" ]]; then
    warn "Já existe um arquivo de configuração: ${tfvars}"
    ask "Deseja usá-lo (S) ou gerar um novo (N)" USAR_EXISTENTE "S"
    case "$USAR_EXISTENTE" in
      [Ss])
        ok "Usando configuração existente."
        return 0
        ;;
      [Nn])
        rm -f "$tfvars"
        warn "Arquivo removido. Gerando nova configuração."
        return 1
        ;;
      *)
        erro "Opção inválida (${USAR_EXISTENTE}). Gerando nova configuração."
        rm -f "$tfvars"
        return 1
        ;;
    esac
  fi

  return 1
}

setup_aws() {
  info "=== AWS ==="
  if check_existing_tfvars aws; then
    run_terraform aws
    return
  fi

  local dir
  dir="$(prepare_dir aws)"

  ask_secret "AWS Access Key ID" AK
  ask_secret "AWS Secret Access Key" SK
  ask "Região" REGIAO "us-east-1"
  ask "Tipo de instância" TIPO "t3.micro"
  ask "ID da AMI (vazio = Ubuntu 22.04 LTS)" AMI ""
  ask "Nome do servidor" NOME "servidor-basico"
  ask_ssh_key

  cat > "${dir}/terraform.tfvars" <<EOF
# Credenciais AWS (não versionar este arquivo)
aws_access_key = "$(hcl_escape "$AK")"
aws_secret_key = "$(hcl_escape "$SK")"
aws_region     = "$(hcl_escape "$REGIAO")"
instance_type  = "$(hcl_escape "$TIPO")"
ami_id         = "$(hcl_escape "$AMI")"
server_name    = "$(hcl_escape "$NOME")"
ssh_public_key = "$(hcl_escape "$SSH_PUBLIC_KEY")"
EOF
  ok "terraform.tfvars gerado em ${dir}"
  run_terraform aws
}

setup_gcp() {
  info "=== GCP ==="
  if check_existing_tfvars gcp; then
    run_terraform gcp
    return
  fi

  local dir
  dir="$(prepare_dir gcp)"

  ask "ID do Projeto (project_id)" PROJETO
  ask "Caminho do arquivo de credenciais (service account .json)" CRED "${HOME}/.config/gcloud/application_default_credentials.json"
  ask "Região" REGIAO "us-central1"
  ask "Zona" ZONA "us-central1-a"
  ask "Tipo de máquina" TIPO "e2-micro"
  ask "Nome do servidor" NOME "servidor-basico"
  ask_ssh_key

  if [[ ! -f "$CRED" ]]; then
    erro "Arquivo de credenciais não encontrado: $CRED"
    return 1
  fi

  cat > "${dir}/terraform.tfvars" <<EOF
# Credenciais GCP (não versionar este arquivo)
gcp_project_id       = "$(hcl_escape "$PROJETO")"
gcp_credentials_file = "$(hcl_escape "$CRED")"
gcp_region           = "$(hcl_escape "$REGIAO")"
gcp_zone             = "$(hcl_escape "$ZONA")"
gcp_machine_type     = "$(hcl_escape "$TIPO")"
server_name          = "$(hcl_escape "$NOME")"
ssh_public_key       = "$(hcl_escape "$SSH_PUBLIC_KEY")"
EOF
  ok "terraform.tfvars gerado em ${dir}"
  run_terraform gcp
}

setup_azure() {
  info "=== Azure ==="
  if check_existing_tfvars azure; then
    run_terraform azure
    return
  fi

  local dir
  dir="$(prepare_dir azure)"

  ask_secret "Subscription ID" SUB
  ask_secret "Tenant ID" TENANT
  ask_secret "Client ID (App ID)" CLIENT
  ask_secret "Client Secret" SECRET
  ask "Localização (location)" LOC "eastus"
  ask "Tamanho da VM" TAM "Standard_B1s"
  ask "Nome do servidor" NOME "servidor-basico"
  ask_ssh_key

  cat > "${dir}/terraform.tfvars" <<EOF
# Credenciais Azure (não versionar este arquivo)
azure_subscription_id = "$(hcl_escape "$SUB")"
azure_tenant_id       = "$(hcl_escape "$TENANT")"
azure_client_id       = "$(hcl_escape "$CLIENT")"
azure_client_secret   = "$(hcl_escape "$SECRET")"
azure_location        = "$(hcl_escape "$LOC")"
azure_vm_size         = "$(hcl_escape "$TAM")"
server_name           = "$(hcl_escape "$NOME")"
ssh_public_key        = "$(hcl_escape "$SSH_PUBLIC_KEY")"
EOF
  ok "terraform.tfvars gerado em ${dir}"
  run_terraform azure
}

setup_oci() {
  info "=== Oracle Cloud (OCI) ==="
  if check_existing_tfvars oci; then
    run_terraform oci
    return
  fi

  local dir
  dir="$(prepare_dir oci)"

  ask "Tenancy OCID" TENANCY
  ask "User OCID" USER_OCID
  ask "Fingerprint" FINGERPRINT
  ask "Caminho da chave privada (PEM)" PRIVKEY "${HOME}/.oci/oci_api_key.pem"
  ask "Região" REGIAO "sa-saopaulo-1"
  ask "Compartment OCID" COMPARTMENT
  ask "Shape da instância" SHAPE "VM.Standard.A1.Flex"
  ask "OCPUs (0 = shape não-flexível)" OCPUS "2"
  ask "Memória em GB (0 = shape não-flexível)" MEMORIA "12"
  ask "Nome do servidor" NOME "servidor"
  ask_ssh_key

  if [[ ! -f "$PRIVKEY" ]]; then
    erro "Chave privada não encontrada: $PRIVKEY"
    return 1
  fi

  cat > "${dir}/terraform.tfvars" <<EOF
# Credenciais OCI (não versionar este arquivo)
oci_tenancy_ocid     = "$(hcl_escape "$TENANCY")"
oci_user_ocid        = "$(hcl_escape "$USER_OCID")"
oci_fingerprint      = "$(hcl_escape "$FINGERPRINT")"
oci_private_key_path = "$(hcl_escape "$PRIVKEY")"
oci_region           = "$(hcl_escape "$REGIAO")"
oci_compartment_ocid = "$(hcl_escape "$COMPARTMENT")"
oci_shape            = "$(hcl_escape "$SHAPE")"
oci_ocpus            = $(hcl_escape "$OCPUS")
oci_memory_in_gbs    = $(hcl_escape "$MEMORIA")
server_name          = "$(hcl_escape "$NOME")"
ssh_public_key       = "$(hcl_escape "$SSH_PUBLIC_KEY")"
EOF
  ok "terraform.tfvars gerado em ${dir}"
  run_terraform oci
}

setup_proxmox() {
  info "=== Proxmox VE ==="
  if check_existing_tfvars proxmox; then
    run_terraform proxmox
    return
  fi

  local dir
  dir="$(prepare_dir proxmox)"

  ask "URL da API (ex.: https://pve.exemplo.com:8006/api2/json)" URL
  ask "Token ID (ex.: terraform@pve!token)" TOKEN_ID
  ask_secret "Token Secret" TOKEN_SECRET
  ask "Nome do node (ex.: pve)" NODE
  ask "VM ID (numérico)" VM_ID "100"
  ask "Template a clonar (VM ID do template com cloud-init)" TEMPLATE_ID "9000"
  ask "Nome do servidor" NOME "servidor-basico"
  ask "Usuário SSH dentro da VM" VM_USER "ubuntu"
  ask_ssh_key

  cat > "${dir}/terraform.tfvars" <<EOF
# Credenciais Proxmox (não versionar este arquivo)
proxmox_api_url         = "$(hcl_escape "$URL")"
proxmox_token_id        = "$(hcl_escape "$TOKEN_ID")"
proxmox_token_secret    = "$(hcl_escape "$TOKEN_SECRET")"
proxmox_node            = "$(hcl_escape "$NODE")"
proxmox_vm_id           = $(hcl_escape "$VM_ID")
proxmox_template_id     = $(hcl_escape "$TEMPLATE_ID")
vm_name                 = "$(hcl_escape "$NOME")"
vm_user                 = "$(hcl_escape "$VM_USER")"
ssh_public_key          = "$(hcl_escape "$SSH_PUBLIC_KEY")"
EOF
  ok "terraform.tfvars gerado em ${dir}"
  run_terraform proxmox
}

menu() {
  clear 2>/dev/null || true
  info "=============================================="
  info "  CRIAÇÃO DE SERVIDOR BÁSICO NA NUVEM"
  info "=============================================="
  echo
  echo "  1) AWS (Amazon Web Services)"
  echo "  2) GCP (Google Cloud Platform)"
  echo "  3) Azure (Microsoft)"
  echo "  4) OCI (Oracle Cloud Infrastructure)"
  echo "  5) Proxmox VE (on-premise)"
  echo "  0) Sair"
  echo
  ask "Selecione a cloud desejada" OPCAO
  echo
  case "$OPCAO" in
    1) setup_aws ;;
    2) setup_gcp ;;
    3) setup_azure ;;
    4) setup_oci ;;
    5) setup_proxmox ;;
    0) info "Saindo."; exit 0 ;;
    *) erro "Opção inválida: $OPCAO"; exit 1 ;;
  esac
}

if ! command -v terraform >/dev/null 2>&1; then
  erro "terraform não encontrado no PATH. Instale antes de continuar."
  exit 1
fi

menu
