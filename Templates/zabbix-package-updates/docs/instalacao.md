# Instalação

> Esta documentação cobre a versão de desenvolvimento 0.1.0-dev.

## Pré-requisitos

- Linux suportado;
- Zabbix Agent ou Agent 2;
- Bash;
- sudo;
- timeout;
- flock;
- stat;
- readlink;
- package manager nativo.

## Instalação pelo repositório clonado

Entre no diretório:

```bash
cd Templates/zabbix-package-updates
```

Execute:

```bash
sudo ./install/install.sh
```

O instalador não aceita argumentos.

## Arquivos instalados

Coletor:

```text
/usr/local/scripts/zabbix-package-updates
```

Configuração:

```text
/etc/zabbix-package-updates.conf
```

Sudoers:

```text
/etc/sudoers.d/zabbix-package-updates
```

UserParameter, conforme o Agent disponível:

```text
/etc/zabbix/zabbix_agent2.d/zabbix-package-updates.conf
/etc/zabbix/zabbix_agentd.d/zabbix-package-updates.conf
```

## Validação manual

Teste a regra privilegiada exatamente como o Agent a utilizará:

```bash
sudo -u zabbix sudo -n -- /usr/local/scripts/zabbix-package-updates
```

O retorno deve ser um JSON com `schema_version` 1.

## Teste do Agent 2

```bash
zabbix_agent2 -t linux.package.updates
```

## Teste do Agent clássico

```bash
zabbix_agentd -t linux.package.updates
```

## Importação do template

Zabbix 7.0:

```text
templates/7.0/template_linux_package_updates.yaml
```

Zabbix 8.0:

```text
templates/8.0/template_linux_package_updates.yaml
```

Os templates ainda estão em fase de validação de laboratório.

## Desinstalação

```bash
sudo ./install/uninstall.sh
```

Por segurança, a desinstalação preserva configuração local, cache, backups e logs.
