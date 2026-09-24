# Arquitetura

```text
Zabbix Server/Proxy
       |
       v
Zabbix Agent / Agent 2
       |
       v
/usr/local/scripts/zabbix-dovecot
       |
       +-- doveadm who -1
       +-- POSIX shell / awk
       v
JSON master item
       |
       v
dependent items
```

O coletor roda no host monitorado; não é um External Check do Server/Proxy. Uma única consulta `doveadm who -1` alimenta os contadores derivados.
