# Validação

Desenvolvimento:
```sh
sh -n scripts/zabbix-dovecot
sh tests/test_core.sh
python3 tests/validate_templates.py
```

No host, confirme propriedade/mode do coletor, ausência de escrita pelo usuário zabbix, JSON válido, ausência de usernames no JSON e tempo de execução abaixo do timeout do Agent.

No Zabbix, importe primeiro em homologação e revise Latest data, triggers, graphs, macros e o diff do importador.
