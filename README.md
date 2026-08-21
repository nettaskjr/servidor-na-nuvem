# Servidor na Nuvem

Projeto didático para **criar um servidor básico (VM) de forma automatizada** em cinco ambientes diferentes usando **Shell Script + Terraform**:

| # | Cloud | Provider Terraform |
|---|-------|--------------------|
| 1 | AWS (Amazon Web Services) | `hashicorp/aws` |
| 2 | GCP (Google Cloud Platform) | `hashicorp/google` |
| 3 | Azure (Microsoft) | `hashicorp/azurerm` |
| 4 | OCI (Oracle Cloud Infrastructure) | `oracle/oci` |
| 5 | Proxmox VE (on-premise) | `bpg/proxmox` |

A ideia é simples: você roda **um único script**, responde algumas perguntas (como qual cloud usar e as credenciais de acesso) e o próprio script gera o arquivo de configuração `terraform.tfvars` e executa o Terraform para provisionar o servidor.

---

## Como funciona (visão geral)

O fluxo é dividido em três etapas:

1. **Coleta de dados** — o script `create-server.sh` faz perguntas interativas (cloud, tokens, usuários, senhas, região, etc.).
2. **Geração do `terraform.tfvars`** — as respostas são gravadas em `terraform/<cloud>/terraform.tfvars`, um arquivo que **contém segredos e nunca deve ir para o GitHub**.
3. **Provisionamento** — o script chama o Terraform (`init`, `validate`, `plan` e, após sua confirmação, `apply`) para criar a máquina.

> **Importante:** cada resposta sensível (senhas, tokens, secrets) é digitada com `read -s`, ou seja, **sem aparecer na tela**. E o `.gitignore` garante que o `terraform.tfvars` e os arquivos de estado não sejam enviados ao repositório.

---

## Pré-requisitos

- **Terraform** instalado (versão >= 1.3)
  - [Download oficial](https://developer.hashicorp.com/terraform/downloads)
  - Testar: `terraform version`
- **Bash** (Linux/macOS; no Windows use WSL ou Git Bash)
- Uma **chave SSH** para acessar o servidor após criado (se não tiver, gere com `ssh-keygen`)
- Uma **conta ativa** na cloud escolhida, com as credenciais prontas (veja a seção "Pré-requisitos por cloud" abaixo).

---

## Passo a passo de utilização

### 1. Clone o repositório

```bash
git clone <url-do-repositorio>
cd servidor-na-nuvem
```

### 2. Torne o script executável (se necessário)

```bash
chmod +x create-server.sh
```

### 3. Execute o script

```bash
./create-server.sh
```

### 4. Escolha a cloud

Aparecerá um menu numérico:

```
==============================================
  CRIAÇÃO DE SERVIDOR BÁSICO NA NUVEM
==============================================

  1) AWS (Amazon Web Services)
  2) GCP (Google Cloud Platform)
  3) Azure (Microsoft)
  4) OCI (Oracle Cloud Infrastructure)
  5) Proxmox VE (on-premise)
  0) Sair

? Selecione a cloud desejada:
```

Digite o número correspondente e pressione **Enter**.

> **Arquivo de configuração já existente:** se o `terraform.tfvars` da cloud escolhida já existir, o script avisa e pergunta se você quer **usá-lo** (inicia a criação/atualização do servidor com aquelas credenciais) ou **gerar um novo** (apaga o arquivo e refaz todas as perguntas). Isso vale para todas as clouds.

### 5. Responda as perguntas da cloud

O script fará perguntas específicas para a cloud escolhida. Exemplo para AWS:

```
? AWS Access Key ID:                    (digitado sem aparecer)
? AWS Secret Access Key:                (digitado sem aparecer)
? Região [us-east-1]:
? Tipo de instância [t3.micro]:
? ID da AMI (vazio = Ubuntu 22.04 LTS) []:
? Nome do servidor [servidor-basico]:
? Caminho da chave pública SSH [/home/usuario/.ssh/id_rsa.pub]:
```

- Valores entre colchetes são **padrões** (pressione Enter para aceitar).
- Senhas e tokens não aparecem ao digitar (modo seguro).

### 6. Confirme a aplicação

O script executa o Terraform e, ao final, pergunta:

```
? Aplicar as mudanças agora (S/n):
```

- Digite `S` (ou Enter) para criar o servidor.
- Digite `n` para apenas gerar o plano sem aplicar.

### 7. Acesse o servidor

Ao final, o Terraform exibe o IP público e um comando pronto, por exemplo:

```
public_ip = "54.123.45.67"
ssh_command = "ssh -i ~/.ssh/id_rsa ubuntu@54.123.45.67"
```

Basta copiar e executar o comando SSH.

---

## Estrutura do projeto

```
servidor-na-nuvem/
├── .gitignore                 # Ignora segredos (terraform.tfvars, *.tfstate, chaves)
├── create-server.sh           # Menu + perguntas + geração do tfvars + execução
└── terraform/
    ├── aws/
    │   ├── main.tf            # Recursos (instância, key pair, security group)
    │   └── variables.tf       # Variáveis declaradas
    ├── gcp/
    │   ├── main.tf
    │   └── variables.tf
    ├── azure/
    │   ├── main.tf
    │   └── variables.tf
    ├── oci/
    │   ├── main.tf
    │   └── variables.tf
    └── proxmox/
        ├── main.tf
        └── variables.tf
```

---

## Segurança (o que NÃO vai para o GitHub)

O `.gitignore` já exclui do versionamento:

- `terraform.tfvars` e `*.tfvars` → credenciais
- `*.tfstate` e `*.tfstate.*` → estado pode conter dados sensíveis
- `.terraform/` → plugins e caches locais
- `*.pem`, `*.key`, `*.p12` → chaves privadas
- `*-private-key.json` e `*credentials*.json` → arquivos de credenciais

**Nunca** force (`git add -f`) o `terraform.tfvars` no repositório.

---

## Pré-requisitos por cloud

### 1. AWS

| Dado | Onde encontrar |
|------|----------------|
| Access Key ID | IAM → Users → seu usuário → Security credentials → Create access key |
| Secret Access Key | Mesmo local (só aparece na criação da chave) |
| Região | Ex.: `us-east-1`, `sa-east-1` |

A conta precisa de permissão para criar EC2, KeyPair e Security Group.

### 2. GCP

| Dado | Onde encontrar |
|------|----------------|
| Project ID | Console → seletor de projeto |
| Arquivo de credenciais | IAM & Admin → Service Accounts → criar chave JSON |

Habilite a **Compute Engine API** no projeto.

### 3. Azure

| Dado | Onde encontrar |
|------|----------------|
| Subscription ID | Portal → Subscriptions |
| Tenant ID | Azure Active Directory → Properties |
| Client ID e Secret | App registrations → seu app → Certificates & secrets |

Crie um **Service Principal** com `az ad sp create-for-rbac`.

### 4. OCI (Oracle)

| Dado | Onde encontrar |
|------|----------------|
| Tenancy OCID | Profile → Tenancy |
| User OCID | Profile → User |
| Fingerprint | Após subir a chave pública de API |
| Chave privada PEM | Gerada com `openssl` e registrada no console |

### 5. Proxmox VE

| Dado | Onde encontrar |
|------|----------------|
| URL da API | `https://seu-pve:8006/api2/json` |
| Token ID | Datacenter → Permissions → API Tokens |
| Token Secret | Gerado junto com o token |
| Node | Ex.: `pve` |
| Template ID | ID do template com **cloud-init** (ex.: 9000) |

> É necessário ter um template de VM com cloud-init preparado no Proxmox. O script clona esse template.

---

## Comandos úteis

| Ação | Comando |
|------|---------|
| Re-executar o menu | `./create-server.sh` |
| Ver o que será criado | `cd terraform/<cloud> && terraform plan` |
| Destruir o servidor | `cd terraform/<cloud> && terraform destroy` |
| Validar sintaxe | `cd terraform/<cloud> && terraform validate` |
| Formatar arquivos | `terraform fmt -recursive terraform/` |
| Validar o script shell | `shellcheck create-server.sh` |

---

## Exemplo completo (AWS)

```bash
$ ./create-server.sh

  1) AWS (Amazon Web Services)
  2) GCP (Google Cloud Platform)
  3) Azure (Microsoft)
  4) OCI (Oracle Cloud Infrastructure)
  5) Proxmox VE (on-premise)
  0) Sair

? Selecione a cloud desejada: 1

=== AWS ===
? AWS Access Key ID: AKIA...                (oculto)
? AWS Secret Access Key: ********           (oculto)
? Região [us-east-1]: sa-east-1
? Tipo de instância [t3.micro]:
? ID da AMI (vazio = Ubuntu 22.04 LTS) []:
? Nome do servidor [servidor-basico]: meu-servidor
? Caminho da chave pública SSH [/home/usuario/.ssh/id_rsa.pub]:

terraform.tfvars gerado em /home/usuario/servidor-na-nuvem/terraform/aws
Executando Terraform em /home/usuario/servidor-na-nuvem/terraform/aws
...
? Aplicar as mudanças agora (S/n): S

Apply complete!

public_ip = "18.230.100.42"
ssh_command = "ssh -i ~/.ssh/id_rsa ubuntu@18.230.100.42"
```

---

## Solução de problemas

| Problema | Causa provável | Solução |
|----------|----------------|---------|
| `terraform não encontrado no PATH` | Terraform não instalado | Instale o Terraform |
| `Chave pública não encontrada` | Caminho do SSH errado | Gere com `ssh-keygen` e informe o caminho correto |
| `Access Denied` na cloud | Permissões insuficientes | Verifique as permissões da conta/role |
| Erro de autenticação | Credencial copiada errada | Re-execute o script e confira os valores |
| Template não encontrado (Proxmox) | Template sem cloud-init | Prepare o template com cloud-init |
