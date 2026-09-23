# Zabbix Package Updates

> **Status:** em desenvolvimento — versão inicial de monitoramento.

Projeto para monitorar atualizações de pacotes Linux pelo Zabbix com foco em **segurança, baixo privilégio e baixo impacto operacional**.

A versão atual é **somente de monitoramento**. Ela não instala, remove, faz purge nem aplica atualizações de pacotes.

## Objetivo

O projeto coleta, normaliza e envia ao Zabbix informações como:

- quantidade de atualizações disponíveis;
- quantidade de atualizações de segurança;
- distribuição Linux e versão;
- package manager detectado;
- necessidade de reboot, quando a distribuição permitir detecção confiável;
- horário da última atualização dos metadados dos repositórios;
- lista dos pacotes com versão instalada e disponível.

O mesmo formato JSON é usado independentemente do package manager, permitindo que os templates do Zabbix permaneçam independentes da distribuição.

## Zabbix suportado

- Zabbix 7.0 LTS;
- Zabbix 8.0.

Os templates são mantidos separadamente:

```text
templates/
├── 7.0/
│   └── template_linux_package_updates.yaml
└── 8.0/
    └── template_linux_package_updates.yaml
```

Todo o conteúdo dos templates permanece em inglês.

## Distribuições inicialmente suportadas

Família Debian:

- Debian;
- Ubuntu;
- Linux Mint;
- Proxmox VE.

Família RPM:

- Red Hat Enterprise Linux;
- Rocky Linux;
- AlmaLinux;
- CentOS Stream;
- Oracle Linux;
- Fedora.

O suporte RPM utiliza DNF5, DNF ou YUM quando disponível. A compatibilidade com versões antigas de YUM ainda deve ser considerada experimental até testes adicionais.

## Arquitetura

```text
Zabbix Server
      |
      | protocolo normal do Zabbix Agent
      v
Zabbix Agent / Agent 2
      |
      | UserParameter fixo
      v
sudo -n /usr/local/scripts/zabbix-package-updates
      |
      +-- detecta a distribuição
      +-- atualiza metadata somente quando necessário
      +-- consulta atualizações
      +-- normaliza o resultado
      |
      v
JSON
```

### Por que `/usr/local/scripts`?

O coletor roda **no host Linux monitorado**, chamado localmente pelo Zabbix Agent/Agent 2.

Ele não é um External Check executado pelo Zabbix Server ou pelo Zabbix Proxy. Por esse motivo, o projeto não utiliza o diretório configurado pela opção `ExternalScripts` do Server/Proxy.

O caminho:

```text
/usr/local/scripts/zabbix-package-updates
```

é uma convenção deste projeto para separar scripts administrativos locais dos arquivos gerenciados pelos pacotes do Zabbix e dos External Checks executados pelo Server/Proxy.

Alterar `ExternalScripts` no Zabbix Server ou Proxy não altera o caminho deste coletor.

## Segurança

O projeto foi desenhado para não transformar o Zabbix em um shell root distribuído.

O usuário `zabbix` recebe somente permissão para executar:

```text
/usr/local/scripts/zabbix-package-updates
```

Não recebe acesso direto a:

```text
apt
apt-get
dnf
dnf5
yum
rpm
dpkg
bash
sh
```

O UserParameter é fixo e não aceita parâmetros.

O coletor atual também rejeita qualquer argumento recebido pela linha de comando.

O arquivo instalado deve ser:

```text
root:root
0755
```

e o diretório `/usr/local/scripts` deve ser de propriedade do root e não gravável por grupo ou outros usuários.

## Atualizações de repositório

O Zabbix pode consultar o item periodicamente sem executar uma atualização dos metadados em toda coleta.

Valor inicial:

```text
REFRESH_INTERVAL=21600
```

equivalente a 6 horas.

No Debian/Ubuntu, por exemplo, `apt-get update` somente é executado quando o cache de metadados está vencido.

## Dependências

A implementação inicial utiliza Bash e ferramentas normalmente presentes nas distribuições suportadas:

- `sudo`;
- `timeout` (coreutils);
- `flock` (util-linux);
- `stat`;
- `readlink`;
- package manager nativo;
- Zabbix Agent ou Agent 2.

Não há dependência de Python, Perl, Node.js ou banco de dados adicional.

## Instalação para desenvolvimento/teste

Clone o repositório e execute como root, a partir deste diretório de projeto:

```bash
cd Templates/zabbix-package-updates
sudo ./install/install.sh
```

O instalador:

1. valida os arquivos de origem;
2. cria `/usr/local/scripts` quando necessário;
3. instala o coletor;
4. instala configuração local;
5. instala uma regra de sudo restrita;
6. valida o sudoers com `visudo`;
7. instala o UserParameter;
8. testa execução como root;
9. testa execução pelo usuário `zabbix`;
10. recarrega ou reinicia o Agent quando necessário.

## Teste manual

Após a instalação:

```bash
sudo -u zabbix sudo -n -- /usr/local/scripts/zabbix-package-updates
```

O retorno deve ser JSON.

Para testar a chave do Agent:

```bash
zabbix_agent2 -t linux.package.updates
```

ou, para o Agent clássico:

```bash
zabbix_agentd -t linux.package.updates
```

## Configuração

Arquivo local:

```text
/etc/zabbix-package-updates.conf
```

Configuração inicial:

```ini
CHECK_ENABLED=yes
REFRESH_ENABLED=yes
REFRESH_INTERVAL=21600
COMMAND_TIMEOUT=120

APPLY_SECURITY_ENABLED=no
APPLY_ALL_ENABLED=no
AUTO_REBOOT=no
```

As três últimas opções são reservadas para evolução futura e **devem permanecer desabilitadas** na versão atual.

## Importação do template

Escolha o arquivo correspondente à sua versão do Zabbix:

```text
templates/7.0/template_linux_package_updates.yaml
templates/8.0/template_linux_package_updates.yaml
```

Os templates iniciais estão em fase de validação e devem ser testados em laboratório antes de uso em produção.

## Limitações atuais

- nenhuma atualização é aplicada;
- nenhuma instalação ou remoção de pacote é permitida;
- detecção de security updates via APT é inicialmente baseada no repositório de origem e será refinada;
- detecção de reboot em RPM depende de `needs-restarting`, quando disponível;
- suporte a YUM legado ainda requer testes adicionais;
- SUSE/Zypper, Alpine/APK e Arch/Pacman ainda não estão implementados;
- templates 7.0/8.0 ainda precisam passar por validação de import e coleta em laboratório.

## Estrutura

```text
zabbix-package-updates/
├── AGENTS.md
├── README.md
├── templates/
│   ├── 7.0/
│   └── 8.0/
├── scripts/
├── config/
├── install/
├── docs/
└── tests/
```

## Próximos passos

1. validar o coletor em Debian 12/13;
2. validar em Ubuntu 22.04/24.04;
3. validar em Proxmox VE 8/9;
4. validar em Rocky/Alma/RHEL;
5. importar e validar o template 7.0;
6. importar e validar o template 8.0;
7. aprimorar classificação de security updates;
8. adicionar novas famílias Linux.

## Licença

A licença definitiva do projeto ainda será definida pelo mantenedor antes da primeira versão estável.
