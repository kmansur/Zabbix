# Instalação

Instale o coletor em `/usr/local/scripts/zabbix-dovecot` com propriedade administrativa e modo 0755.

Instale `config/userparameter.conf` no include do Zabbix Agent.

Teste o `doveadm who -1` diretamente como usuário zabbix. Se funcionar, não instale sudoers. Se falhar por permissão do socket, use somente o exemplo correspondente em `config/` e valide com `visudo -cf`.

Depois teste:
```sh
sudo -u zabbix /usr/local/scripts/zabbix-dovecot stats
sudo -u zabbix /usr/local/scripts/zabbix-dovecot version
sudo -u zabbix /usr/local/scripts/zabbix-dovecot collector-version
```
