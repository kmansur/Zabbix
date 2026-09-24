# Migração

Origem: `kmansur/Zabbix_Templates/Dovecot`

Destino: `kmansur/Zabbix/Templates/zabbix-dovecot`

Renomeações principais:
```text
dovecot_stats.sh            -> scripts/zabbix-dovecot
userparameter_dovecot.conf  -> config/userparameter.conf
Template_Dovecot_7.0.yaml   -> templates/7.0/template_dovecot.yaml
Template_Dovecot_8.0.yaml   -> templates/8.0/template_dovecot.yaml
Template App Dovecot        -> Dovecot by Zabbix agent
Net Tech                    -> NetTech
```

No host, instale o novo coletor e UserParameter antes de remover os arquivos antigos.

As item keys e UUIDs foram preservados sempre que possível. Faça a importação em homologação e confirme que o template existente é atualizado, não duplicado.
