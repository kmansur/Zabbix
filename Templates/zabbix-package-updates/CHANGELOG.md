# Changelog

## [0.1.0-dev] - 2026-09-23

### Adicionado

- coletor Linux de atualizações em modo somente monitoramento;
- suporte inicial para APT;
- suporte inicial para DNF5 e DNF;
- identificação de Proxmox VE;
- formato JSON normalizado;
- cache de atualização dos metadados dos repositórios;
- lock contra execuções concorrentes;
- timeout para comandos externos;
- validação de propriedade e permissões do coletor/configuração;
- regra sudo restrita ao coletor;
- UserParameter sem argumentos;
- instalador e desinstalador;
- template inicial para Zabbix 7.0;
- template inicial para Zabbix 8.0;
- documentação inicial em português do Brasil.

### Segurança

- nenhuma função de instalação, remoção, purge ou aplicação de updates;
- argumentos de linha de comando rejeitados pelo coletor;
- execução privilegiada limitada ao coletor;
- configuração de remediação falha fechada quando habilitada nesta versão;
- nenhum uso de `eval`, `sh -c` ou comandos arbitrários recebidos do Zabbix.

### Conhecido

- classificação de security updates no APT ainda usa heurística baseada no repositório;
- YUM legado ainda necessita validação adicional;
- templates precisam de validação de importação em instâncias reais Zabbix 7.0 e 8.0.
