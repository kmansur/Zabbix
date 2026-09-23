# Troubleshooting

## ROOT_REQUIRED

O coletor deve ser chamado através da regra sudo restrita:

```bash
sudo -u zabbix sudo -n -- /usr/local/scripts/zabbix-package-updates
```

## INSECURE_COLLECTOR / INSECURE_FILE

Verifique propriedade e permissões:

```bash
ls -ld /usr/local/scripts
ls -l /usr/local/scripts/zabbix-package-updates
ls -l /etc/zabbix-package-updates.conf
```

Esperado para o coletor:

```text
root:root 0755
```

## REPOSITORY_REFRESH_FAILED

Teste o refresh diretamente pelo package manager do sistema.

Debian/Ubuntu/Proxmox:

```bash
apt-get update
```

RPM:

```bash
dnf makecache --refresh
```

Corrija DNS, proxy, certificados, chaves ou repositórios. Não desabilite validação de assinatura para contornar o problema.

## COLLECTOR_BUSY

Outra coleta ainda está em execução. Verifique processos antes de tomar qualquer ação.

Não remova locks do package manager.

## REMEDIATION_NOT_SUPPORTED

A versão atual não aplica atualizações. Confirme:

```ini
APPLY_SECURITY_ENABLED=no
APPLY_ALL_ENABLED=no
AUTO_REBOOT=no
```

## Teste do UserParameter

Agent 2:

```bash
zabbix_agent2 -t linux.package.updates
```

Agent clássico:

```bash
zabbix_agentd -t linux.package.updates
```

## Sudo solicitando senha

Valide:

```bash
visudo -cf /etc/sudoers.d/zabbix-package-updates
sudo -u zabbix sudo -n -- /usr/local/scripts/zabbix-package-updates
```

O comando deve executar sem prompt interativo.
