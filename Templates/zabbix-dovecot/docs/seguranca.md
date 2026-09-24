# Segurança

- execute o coletor como usuário zabbix;
- não conceda sudo ao coletor;
- permita somente o comando exato `doveadm who -1` se necessário;
- mantenha o script não gravável pelo usuário zabbix;
- não use UserParameter flexível;
- não envie usernames ao Zabbix;
- não reduza permissões de arquivos com credenciais para permitir checksum;
- não use `SETENV`, `system.run[]` ou shell root genérico.
