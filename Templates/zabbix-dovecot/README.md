# Zabbix Dovecot

> **Status:** em desenvolvimento — versão 3.0.0.

Monitoramento do Dovecot pelo Zabbix com foco em segurança, baixo privilégio, desempenho e compatibilidade com FreeBSD e Linux.

Este projeto foi migrado de `kmansur/Zabbix_Templates/Dovecot` para a estrutura central `kmansur/Zabbix/Templates/zabbix-dovecot`.

## Padrão do projeto

```text
Templates/zabbix-dovecot/
├── AGENTS.md
├── CHANGELOG.md
├── LICENSE
├── README.md
├── config/
├── docs/
├── legacy/
├── scripts/
│   └── zabbix-dovecot
├── templates/
│   ├── 7.0/template_dovecot.yaml
│   └── 8.0/template_dovecot.yaml
└── tests/
```

Padrões de nome:
- projeto: `zabbix-dovecot`;
- coletor: `zabbix-dovecot`;
- template exportado: `template_dovecot.yaml`;
- nome técnico no Zabbix: `Dovecot by Zabbix agent`;
- vendor: `NetTech`.

Código, comentários e conteúdo dos templates ficam em inglês. A documentação administrativa fica em português do Brasil.

## Compatibilidade

- Zabbix 7.0 LTS;
- Zabbix 8.0;
- FreeBSD;
- Linux;
- Dovecot 2.3/2.4 mediante validação no host.

O antigo template Zabbix 5.0 permanece em `legacy/`. Não há export suportado para Zabbix 6.0 nesta estrutura.

## Métricas

São preservados os dados do template anterior:
- estado e erro do coletor;
- conexões IMAP;
- conexões POP3;
- total de conexões;
- versão do Dovecot;
- processo master;
- disponibilidade e tempo de resposta dos serviços;
- checksums de configuração.

Também são mantidas as métricas 3.0:
- usuários únicos com sessões IMAP/POP3;
- máximo de conexões simultâneas por usuário;
- versão do coletor.

As **item keys e UUIDs existentes foram preservados** sempre que possível.

## Segurança

O coletor executa como usuário do Zabbix Agent. Não conceda sudo ao script inteiro.

Ele tenta primeiro:

```text
doveadm who -1
```

sem elevação. Se o socket exigir privilégio, somente esse comando exato é permitido via sudo.

FreeBSD:

```text
zabbix ALL=(root) NOPASSWD: /usr/local/bin/doveadm who -1
```

Linux:

```text
zabbix ALL=(root) NOPASSWD: /usr/bin/doveadm who -1
```

## Instalação

```sh
install -o root -g wheel -m 0755 scripts/zabbix-dovecot /usr/local/scripts/zabbix-dovecot
```

No Linux, normalmente use `root:root`.

Instale `config/userparameter.conf` no diretório de includes do Agent/Agent 2. Teste primeiro o `doveadm who -1` diretamente como usuário `zabbix`; instale sudoers somente se necessário.

## Templates

- Zabbix 7.0: `templates/7.0/template_dovecot.yaml`
- Zabbix 8.0: `templates/8.0/template_dovecot.yaml`

Importe primeiro em homologação e revise o diff. A mudança do nome técnico usa o mesmo UUID do template anterior, mas deve ser confirmada no importador real.

## Migração do projeto antigo

O caminho do coletor passa de:

```text
/usr/local/scripts/dovecot_stats.sh
```

para:

```text
/usr/local/scripts/zabbix-dovecot
```

As item keys do Zabbix permanecem as mesmas. Consulte `docs/migracao.md`.

## Testes

```sh
sh -n scripts/zabbix-dovecot
sh tests/test_core.sh
python3 tests/validate_templates.py
```

O host monitorado não precisa de Python.

## Licença

MIT.
