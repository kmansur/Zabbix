# Segurança

## Princípio

O projeto segue menor privilégio e falha fechada.

O objetivo é permitir que o Zabbix consulte atualizações sem fornecer ao Zabbix uma interface genérica de administração root.

## Regra sudo

A regra fornecida limita o usuário `zabbix` ao coletor e sem argumentos.

```sudoers
zabbix ALL=(root) NOPASSWD: /usr/local/scripts/zabbix-package-updates ""
```

O próprio coletor também rejeita argumentos.

Essa duplicação é intencional: a restrição existe tanto na política sudo quanto no programa privilegiado.

## Propriedade

O coletor deve permanecer:

```text
root:root 0755
```

O diretório `/usr/local/scripts` precisa ser de propriedade do root e não pode ser gravável por grupo ou outros usuários.

A configuração local deve ser de propriedade do root e não gravável pelo usuário `zabbix`.

## Comandos arbitrários

São proibidos no projeto:

- `eval`;
- shell construído com entrada externa;
- `sh -c` ou `bash -c` com dados recebidos do Zabbix;
- UserParameter flexível para package management;
- nomes arbitrários de pacotes enviados pelo Zabbix;
- opções arbitrárias de package manager;
- sudo direto para package managers.

## Assinaturas dos repositórios

O projeto não desabilita mecanismos nativos de validação.

Não devem ser utilizados:

- `--allow-unauthenticated`;
- `--nogpgcheck`;
- `trusted=yes` para contornar erros;
- qualquer equivalente que enfraqueça a validação de pacotes.

## Locks

O coletor possui lock próprio para evitar duas execuções simultâneas.

Locks nativos de APT/DNF/YUM nunca devem ser removidos ou contornados pelo projeto.

## Arquivos temporários

Arquivos de trabalho são criados em diretório privado dentro de:

```text
/run/zabbix-package-updates/
```

e não em nomes previsíveis sob `/tmp`.

## Remediação futura

A versão atual é somente leitura/monitoramento.

Os parâmetros abaixo existem somente para reservar a política futura e devem permanecer em `no`:

```ini
APPLY_SECURITY_ENABLED=no
APPLY_ALL_ENABLED=no
AUTO_REBOOT=no
```

Se algum deles for habilitado na versão atual, o coletor recusa a execução.

## Modelo de ameaça

O projeto procura reduzir especialmente:

- command injection;
- privilege escalation através do UserParameter;
- alteração do coletor pelo usuário `zabbix`;
- abuso de PATH;
- symlink attacks em arquivos sensíveis;
- corrida entre coletores;
- execução privilegiada genérica;
- movimento lateral a partir do Zabbix Server.
