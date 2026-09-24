# AGENTS.md — Zabbix Dovecot

## Project
`zabbix-dovecot` monitors Dovecot through Zabbix Agent/Agent 2.

Priority order:
Security > operational safety > compatibility > performance > simplicity > convenience.

## Language
Source code, filenames, directory names, comments, internal messages, and Zabbix template content must be in English.
Administrator-facing documentation must be in Brazilian Portuguese.

## Supported Zabbix
- 7.0 LTS
- 8.0

Maintain separate files:
- templates/7.0/template_dovecot.yaml
- templates/8.0/template_dovecot.yaml

## Naming
- project: zabbix-dovecot
- collector: scripts/zabbix-dovecot
- template file: template_dovecot.yaml
- technical template name: Dovecot by Zabbix agent
- vendor: NetTech
- config/userparameter.conf
- config/sudoers.freebsd.example
- config/sudoers.linux.example

## Backward compatibility
Preserve existing Zabbix item keys and UUIDs unless a breaking change is necessary and documented.
Do not rename keys for cosmetic reasons.

## Security
Run the collector as the unprivileged Zabbix Agent user.
Never grant sudo to the collector itself.
If required, sudo may permit only:
- FreeBSD: /usr/local/bin/doveadm who -1
- Linux: /usr/bin/doveadm who -1

Do not allow unrestricted doveadm, shell interpreters, arbitrary macro-supplied commands, flexible UserParameters, or unsafe system.run usage.
Do not weaken permissions on credential-bearing Dovecot files for checksum monitoring.

## Performance
Prefer one JSON master collection and dependent items.
Do not execute doveadm once per metric when one collection can derive all counters.

## Privacy
Do not send usernames, mailbox names, client IPs, or credentials to Zabbix for aggregate metrics.

## Runtime
Keep the monitored-host collector POSIX shell compatible and dependency-light.
Python/PyYAML is allowed only for development and CI validation.

## Required tests
```sh
sh -n scripts/zabbix-dovecot
sh tests/test_core.sh
python3 tests/validate_templates.py
```

Validate imports in real Zabbix 7.0 and 8.0 homologation environments before release.
