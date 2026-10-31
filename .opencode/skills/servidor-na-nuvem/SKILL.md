---
name: servidor-na-nuvem
description: Use when working on the servidor-na-nuvem project (create-server.sh, Terraform provisioning of VMs on AWS/GCP/Azure/OCI/Proxmox, cloud-init module, terraform.tfvars generation). Covers project structure, per-cloud variable conventions, validation commands, and secret-handling rules.
---

# Servidor na Nuvem

Projeto didático que provisiona uma VM básica em 5 ambientes (AWS, GCP, Azure, OCI, Proxmox) via **um único script Shell interativo** + **Terraform**. O script coleta credenciais, gera `terraform/<cloud>/terraform.tfvars` e roda `init/validate/plan/apply`.

## Mapa do projeto

```
create-server.sh                    # menu + perguntas + gera tfvars + chama terraform
terraform/modules/cloud-init/       # módulo compartilhado (template, main, variables)
terraform/<cloud>/main.tf           # recursos específicos da cloud
terraform/<cloud>/variables.tf      # variáveis (defaults)
terraform/<cloud>/terraform.tfvars  # SEGREDOS — gerado, nunca versionar
README.md                           # documentação principal (pt-BR)
```

Clouds e prefixos de variáveis: `aws_`, `gcp_`, `azure_`, `oci_`, `proxmox_`.

## Regras/segredos (crítico)

- `terraform.tfvars`, `*.tfstate`, `.terraform/`, `*.pem`, `*.key`, credenciais JSON são **ignorados** pelo `.gitignore`. Nunca `git add -f` nesses arquivos.
- Variáveis sensíveis declaram `sensitive = true` (access keys, secrets, client secret, chave PEM, password).
- No script, segredos são lidos com `ask_secret` (`read -rs`); caminhos de arquivo com `ask_path` (valida existência, 3 tentativas).
- Valores gravados no HCL passam por `hcl_escape`; listas de portas são normalizadas para `[22, 80, 443]` com `${PORTAS//,/, }`.
- Não logar/echoar segredos em comandos ou commits.

## Convenções ao alterar código

- **Idioma:** prompts, comentários, mensagens e README em **português (pt-BR)**.
- **Terraform:** `required_version = ">= 1.3"`; providers com `~> major`; cada `.tf` usa `module "cloud_init"` compartilhado.
- **cloud-init:** lógica comum fica em `terraform/modules/cloud-init/cloud-init.yaml.tftpl`. Só altere o template para mudanças globais; parâmetros do módulo: `ssh_public_key`, `os_user`, `cloud_name`, `user_password`.
- **Usuário SSH por cloud:** AWS/GCP/OCI = `ubuntu`; Azure = `azureuser`; Proxmox = variável `proxmox_vm_user`.
- **Nova cloud / nova opção:** adicione função `setup_<cloud>` no script, `case` no `menu()`, e o par `main.tf`/`variables.tf` com o prefixo correspondente. Mantenha o padrão de disco (`*_disk_size`) e portas (`*_open_port_enable`, `*_open_port_numbers`, `*_open_port_cidr`).
- **Outputs:** toda cloud expõe `public_ip`, `ssh_command`, `cloud_init_log_command` (Proxmox expõe `vm_id`/`vm_name`).
- **apply condicional:** `run_terraform` gera `tfplan` e só aplica se o usuário confirmar (`S/n`).

## Comandos de validação

```bash
shellcheck create-server.sh                 # lint do script
terraform fmt -recursive terraform/         # formatação
cd terraform/<cloud> && terraform init -backend=false && terraform validate
cd terraform/<cloud> && terraform plan      # requer terraform.tfvars com credenciais
```

## Ao implementar mudanças

1. Leia `create-server.sh` (menu/perguntas) e o `.tf` da cloud afetada antes de editar.
2. Se mudar uma variável, atualize **os três pontos**: `variables.tf`, a geração do `terraform.tfvars` no script, e o `README.md`.
3. Valide com `shellcheck` e `terraform validate` (use `-backend=false` se não houver credenciais/backend).
4. Não execute `terraform apply`/`destroy` sem confirmação explícita do usuário — isso cria/destrói recursos reais.
5. Lembre que o estado da OCI já existe em `terraform/oci/terraform.tfstate` local; não versione nem sobrescreva.

## Gotchas conhecidos

- Proxmox não parametriza disco (vem do template clonado) e usa `insecure = true` no provider.
- OCI detecta shape ARM (`a1`) e escolhe imagem aarch64; shapes flexíveis usam `oci_ocpus > 0`.
- `check_existing_tfvars` pergunta se reusa ou regenera o `terraform.tfvars` antes de rodar.
- O template cloud-init faz `package_upgrade`, instala Cockpit e reinicia a VM (`power_state.reboot`).
