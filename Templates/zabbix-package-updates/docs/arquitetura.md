# Arquitetura

## Visão geral

O projeto utiliza o Zabbix Agent/Agent 2 para chamar um coletor local instalado no host monitorado.

```text
Zabbix Server
      |
      v
Zabbix Agent / Agent 2
      |
      | UserParameter fixo
      v
sudo -n /usr/local/scripts/zabbix-package-updates
      |
      +--> /etc/os-release
      +--> package manager nativo
      +--> cache/lock local
      |
      v
JSON normalizado
      |
      v
Master item + dependent items
```

## Por que não usar ExternalScripts?

`ExternalScripts` é um mecanismo do Zabbix Server/Proxy para External Checks.

Neste projeto, o comando precisa ser executado **no próprio host Linux monitorado**, pois é nesse host que existem:

- o banco local de pacotes instalados;
- os repositórios configurados;
- o package manager;
- o estado de reboot;
- os locks do package manager.

Por isso o coletor fica em:

```text
/usr/local/scripts/zabbix-package-updates
```

Esse caminho é uma convenção do projeto para scripts administrativos locais e não depende da configuração `ExternalScripts` do Zabbix Server ou Proxy.

## Modelo de coleta

O UserParameter retorna um JSON único. O template usa esse JSON como master item e extrai métricas com dependent items.

Isso evita executar o package manager repetidamente para cada métrica.

## Atualização dos metadados

O coletor mantém:

```text
/var/cache/zabbix-package-updates/last_refresh
```

O refresh padrão ocorre a cada 6 horas.

O diretório de runtime é:

```text
/run/zabbix-package-updates/
```

e é utilizado para lock e arquivos temporários privados.

## Separação de privilégios

O Agent permanece rodando como usuário `zabbix`.

A elevação ocorre somente para o coletor:

```text
zabbix
  |
  v
sudo -n /usr/local/scripts/zabbix-package-updates
  |
  v
root
```

Não existe permissão sudo direta para `apt`, `dnf`, `rpm`, shell ou outros executáveis genéricos.

## Remediação

A versão atual não contém remediação.

Uma eventual versão futura poderá estudar apenas aplicação controlada de atualizações já oferecidas pelos repositórios configurados. Instalação arbitrária, remoção de pacotes e shell privilegiado permanecem fora do escopo.
