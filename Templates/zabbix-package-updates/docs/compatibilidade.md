# Compatibilidade

## Zabbix

| Versão | Estado |
|---|---|
| Zabbix 7.0 LTS | Implementação inicial; importação ainda deve ser validada em laboratório |
| Zabbix 8.0 | Implementação inicial; importação ainda deve ser validada em laboratório |

## Linux

| Família | Detecção | Consulta | Security updates | Reboot |
|---|---|---|---|---|
| Debian | inicial | APT | heurística por repositório | /var/run/reboot-required |
| Ubuntu | inicial | APT | heurística por repositório | /var/run/reboot-required |
| Proxmox VE | inicial | APT | heurística por repositório | /var/run/reboot-required |
| Rocky Linux | inicial | DNF/DNF5 | advisory --security quando suportado | needs-restarting quando disponível |
| AlmaLinux | inicial | DNF/DNF5 | advisory --security quando suportado | needs-restarting quando disponível |
| RHEL | inicial | DNF/DNF5 | advisory --security quando suportado | needs-restarting quando disponível |
| CentOS Stream | inicial | DNF | advisory --security quando suportado | needs-restarting quando disponível |
| Oracle Linux | inicial | DNF | advisory --security quando suportado | needs-restarting quando disponível |
| Fedora | inicial | DNF5/DNF | advisory --security quando suportado | needs-restarting quando disponível |
| YUM legado | experimental | a validar | a validar | a validar |
| SUSE/openSUSE | não implementado | - | - | - |
| Alpine | não implementado | - | - | - |
| Arch | não implementado | - | - | - |

A matriz será atualizada conforme testes reais forem concluídos.
