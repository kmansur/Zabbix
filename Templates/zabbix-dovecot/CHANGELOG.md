# Changelog

## [3.0.0-dev] - 2026-09-24

### Adicionado
- migração para `kmansur/Zabbix`;
- estrutura `Templates/zabbix-dovecot`;
- CI e validação estática;
- métricas agregadas de usuários e conexões por usuário;
- exemplos de sudoers para FreeBSD e Linux.

### Alterado
- coletor renomeado para `zabbix-dovecot`;
- exports renomeados para `template_dovecot.yaml`;
- template técnico renomeado para `Dovecot by Zabbix agent`;
- vendor padronizado como `NetTech`;
- documentação consolidada em pt-BR;
- versões suportadas concentradas em Zabbix 7.0 e 8.0.

### Preservado
- UUIDs e item keys existentes sempre que possível;
- template Zabbix 5.0 em `legacy/`.
