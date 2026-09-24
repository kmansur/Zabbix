# Troubleshooting

## status 0
Execute `sudo -u zabbix /usr/local/scripts/zabbix-dovecot stats` e depois teste `doveadm who -1` diretamente.

## sudo pede senha
Confira o caminho real do doveadm e valide o arquivo com `visudo -cf`.

## checksum unsupported
Não altere permissões de arquivos sensíveis. Desabilite o item no host se a leitura segura não for apropriada.

## IMAPS/POP3S
Esses serviços continuam em check TCP; IMAP/POP3 sem TLS usam validação de protocolo.
