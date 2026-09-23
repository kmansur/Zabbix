# AGENTS.md — Zabbix Package Updates

## Project Overview

`zabbix-package-updates` is a security-focused project for monitoring available Linux package updates through Zabbix.

The project must support multiple Linux distributions and must keep monitoring separate from privileged remediation.

The primary purpose of the project is **monitoring and visibility**. Arbitrary package installation, package removal, and generic package-management execution are explicitly out of scope. A future remediation feature may only apply updates already offered by the host's configured and trusted repositories, and it must always be explicitly enabled, tightly restricted, locally authorized, and auditable.

---

# 1. Project Language

## Source Code

All source code must be written in English.

This includes:

- variable names;
- function names;
- constants;
- filenames;
- directory names;
- configuration parameters;
- internal messages;
- log messages;
- error messages;
- source code comments.

Do not use Portuguese identifiers in source code.

## Zabbix Templates

All Zabbix template content must be written exclusively in English.

This includes:

- template names;
- item names;
- item keys;
- trigger names;
- discovery rules;
- macros;
- graphs;
- dashboards;
- tags;
- descriptions;
- value maps;
- error messages.

Do not include Portuguese translations inside the Zabbix templates.

## Documentation

All project documentation intended for administrators and users must be written in **Brazilian Portuguese (`pt-BR`)**.

This includes:

- `README.md`;
- installation documentation;
- configuration documentation;
- security documentation;
- architecture documentation;
- troubleshooting guides;
- compatibility documentation;
- examples;
- upgrade guides;
- release notes intended for users.

Technical terms commonly used in English in the Linux and Zabbix ecosystems may remain in English where appropriate.

Documentation must be complete enough for a Linux/Zabbix administrator to deploy and operate the project without reading the source code.

---

# 2. Supported Zabbix Versions

The project must officially support:

- Zabbix 7.0 LTS;
- Zabbix 8.0.

Both versions are first-class supported targets.

Do not introduce functionality that silently breaks compatibility with either supported version.

Maintain separate template files:

```text
templates/
├── 7.0/
│   └── template_linux_package_updates.yaml
└── 8.0/
    └── template_linux_package_updates.yaml
```

The two templates should provide the same logical monitoring capabilities whenever technically possible.

Never assume that a template exported from Zabbix 8.0 can be safely imported into Zabbix 7.0.

Both templates must be independently validated.

Version-specific differences must be documented in Brazilian Portuguese.

---

# 3. Security Is a Primary Requirement

Security is a primary design requirement, not an optional enhancement.

Always prefer:

```text
Security
    >
Operational safety
    >
Compatibility
    >
Simplicity
    >
Convenience
```

Apply least privilege throughout the project.

Any feature that increases privileges, command-execution capability, or attack surface must be explicitly justified and reviewed.

Fail closed whenever privileged functionality is uncertain or misconfigured.

---

# 4. Zabbix Must Not Become a General-Purpose Root Shell

Never implement functionality that allows Zabbix to execute arbitrary commands as root.

The following are prohibited:

```sudoers
zabbix ALL=(root) NOPASSWD: ALL
```

```sudoers
zabbix ALL=(root) NOPASSWD: /usr/bin/apt-get
```

Equivalent unrestricted permissions for the following are also prohibited:

```text
apt
apt-get
dnf
dnf5
yum
zypper
apk
pacman
rpm
dpkg
sh
bash
python
perl
```

Do not enable unrestricted `system.run[]`.

Do not allow arbitrary commands or executable paths supplied by:

- Zabbix macros;
- item parameters;
- action parameters;
- user input;
- environment variables.

---

# 5. Collector Source and Installation Location

The collector source must be stored in the repository at:

```text
scripts/zabbix-package-updates
```

The standard installation path on monitored Linux hosts is:

```text
/usr/local/scripts/zabbix-package-updates
```

This path is a deliberate project convention.

The collector is a **local host-side script invoked through the Zabbix Agent integration**, optionally using narrowly scoped `sudo`. It is **not a Zabbix Server or Zabbix Proxy External Check**.

Therefore, the project must not install the collector in a Zabbix `ExternalScripts` directory merely because it is used by Zabbix.

Using `/usr/local/scripts` keeps the locally maintained administrative collector separate from:

- Zabbix Server external checks;
- Zabbix Proxy external checks;
- distribution-managed Zabbix files;
- Zabbix Server/Proxy `ExternalScripts` configuration.

The project documentation must explain this architectural distinction in Brazilian Portuguese.

At minimum, `README.md` and the installation/architecture documentation must explain that:

1. `ExternalScripts` is associated with Zabbix Server/Proxy external checks;
2. this collector runs on the monitored Linux host;
3. it is invoked locally through the Zabbix Agent integration;
4. `/usr/local/scripts` was chosen to clearly separate locally maintained administrative scripts from Zabbix Server/Proxy external-check directories;
5. changing `ExternalScripts` on the Zabbix Server or Proxy does not control the location of this collector.

Do not describe `/usr/local/scripts` as a mandatory Linux filesystem standard. It is the project's chosen installation convention.

---

# 6. Collector Ownership and Permissions

The installed collector must be owned by root and must not be writable by the `zabbix` user.

Required default:

```text
root:root
0755
```

Installed path:

```text
/usr/local/scripts/zabbix-package-updates
```

The installer must create `/usr/local/scripts` when it does not exist.

The installer must not make the directory or collector writable by:

- `zabbix`;
- `www-data`;
- `apache`;
- `nginx`;
- other unprivileged service accounts.

Any exception must be explicitly justified and documented.

---

# 7. Privilege Separation

The Zabbix Agent must continue running as its normal unprivileged account, normally:

```text
zabbix
```

Privileged package-management operations must be performed only through the dedicated project-controlled collector:

```text
/usr/local/scripts/zabbix-package-updates
```

If `sudo` is required, the sudoers rule must allow only the required collector invocation.

Example baseline:

```sudoers
zabbix ALL=(root) NOPASSWD: /usr/local/scripts/zabbix-package-updates
```

Do not grant direct sudo access to package managers.

Before installing or changing sudoers configuration, validate it with:

```sh
visudo -cf /etc/sudoers.d/zabbix-package-updates
```

If command arguments are later introduced, sudoers rules and collector validation must be reviewed together. Do not assume that a restricted-looking sudoers line is sufficient if the privileged executable itself accepts dangerous arbitrary input.

---

# 8. Agent Integration

The collector is a host-side script.

The initial implementation should integrate with Zabbix Agent or Zabbix Agent 2 using a narrowly scoped key, normally through a dedicated UserParameter or another equally constrained local-agent mechanism.

Example concept:

```ini
UserParameter=linux.package.updates,sudo -n /usr/local/scripts/zabbix-package-updates
```

The final key name may evolve, but it must remain stable once released.

The project must not rely on the Zabbix Server/Proxy `ExternalScripts` setting for this host-side execution.

Use `sudo -n` so that the collector fails instead of waiting for an interactive password prompt.

---

# 9. Command Execution Security

Never construct privileged shell commands from untrusted input.

Prohibited patterns include:

```sh
eval "$COMMAND"
```

and:

```sh
sh -c "$COMMAND"
```

and:

```sh
bash -c "$COMMAND"
```

when the command contains externally controlled data.

Do not dynamically construct privileged command lines from Zabbix input.

Use explicit code paths and predefined operations.

Unknown operations must always be rejected.

If the monitoring-only collector does not require arguments, reject all arguments.

Example:

```sh
if [ "$#" -ne 0 ]; then
    fail_invalid_arguments
fi
```

When remediation is introduced later, use a strict allow-list of supported actions.

---

# 10. Fixed Execution Environment

Privileged scripts must use a controlled environment.

Set a safe PATH explicitly:

```sh
PATH='/usr/sbin:/usr/bin:/sbin:/bin'
export PATH
```

Use an appropriate umask:

```sh
umask 027
```

Whenever practical, call security-sensitive binaries using absolute paths.

Examples:

```text
/usr/bin/apt-get
/usr/bin/dpkg
/usr/bin/dnf
/usr/bin/zypper
```

Do not depend on a caller-controlled PATH.

Do not trust arbitrary environment variables to select package managers, executable paths, configuration files, state directories, or privileged actions.

---

# 11. Package Manager Detection

Use `/etc/os-release` as the primary operating-system identification mechanism.

Initial target families should include:

## Debian family

Examples:

- Debian;
- Ubuntu;
- Linux Mint;
- Raspberry Pi OS;
- Proxmox VE.

Package management:

```text
APT / dpkg
```

## Red Hat family

Examples:

- Red Hat Enterprise Linux;
- Rocky Linux;
- AlmaLinux;
- CentOS Stream;
- Oracle Linux;
- Fedora.

Package management:

```text
DNF
DNF5
YUM where required for compatibility
RPM
```

## SUSE family

Examples:

- SUSE Linux Enterprise Server;
- openSUSE.

Package management:

```text
Zypper
```

Additional package managers may be added later, including:

```text
APK
Pacman
```

Support must be modular.

Adding a package manager must not require redesigning the Zabbix template.

Unsupported distributions must return an explicit unsupported/error state rather than incorrect data.

---

# 12. Normalized JSON Output

Different package managers must produce a normalized output.

The Zabbix template must not need to know whether a host uses APT, DNF, Zypper, or another supported package manager.

Example:

```json
{
  "schema_version": 1,
  "status": "ok",
  "distribution": {
    "id": "debian",
    "name": "Debian GNU/Linux",
    "version": "13"
  },
  "package_manager": "apt",
  "updates": {
    "total": 7,
    "security": 3
  },
  "reboot_required": false,
  "last_refresh": 1790157600,
  "last_check": 1790157900,
  "packages": [
    {
      "name": "openssl",
      "installed": "3.0.17",
      "available": "3.0.18",
      "repository": "security",
      "security": true
    }
  ]
}
```

The JSON schema must remain stable whenever possible.

Breaking schema changes require:

1. a schema version change;
2. template review for both Zabbix versions;
3. migration documentation;
4. CHANGELOG documentation.

---

# 13. Monitoring Architecture

Prefer one master item returning the complete normalized JSON.

Other metrics should normally be implemented as dependent items.

Example:

```text
Master item
    |
    +-- Collector status
    +-- Available updates
    +-- Security updates
    +-- Package manager
    +-- Distribution
    +-- Distribution version
    +-- Reboot required
    +-- Last successful check
    +-- Last repository refresh
```

Avoid invoking the package manager independently for every Zabbix item.

Minimize:

- agent executions;
- repository queries;
- package-manager locks;
- network traffic;
- Zabbix Server load;
- Zabbix database growth.

---

# 14. Repository Metadata Refresh

Operations such as:

```sh
apt-get update
```

must not run every time Zabbix polls the item.

Repository metadata must use a configurable refresh/cache interval.

Recommended initial default:

```text
6 hours
```

Zabbix may query the cached package status more frequently.

The implementation must distinguish:

- metadata refresh time;
- package check time;
- cached-result age.

The refresh process must not create uncontrolled concurrent package-manager operations.

---

# 15. Locking

Package operations must use locking.

Only one project collector/remediation process may manipulate package metadata at a time.

The implementation must respect native package-manager locks.

Never delete native package-manager lock files to force execution.

Never bypass an active package manager.

A lock conflict must result in a controlled status/error response.

---

# 16. Monitoring and Remediation Must Remain Separate

The project must conceptually and technically separate:

```text
CHECK
```

from:

```text
APPLY
```

Monitoring must work when remediation is completely disabled.

The default installation must provide monitoring without granting package-update application capability.

Do not require remediation permissions merely to collect package-update information unless a specific package manager makes a narrowly scoped privileged read/refresh operation necessary.

---

# 17. Default Security Policy

Default behavior:

```text
CHECK_ENABLED=yes
REFRESH_ENABLED=yes
APPLY_SECURITY_ENABLED=no
APPLY_ALL_ENABLED=no
AUTO_REBOOT=no
```

A fresh installation must never automatically apply package updates.

Remediation must always be opt-in.

Automatic reboot must always be disabled by default.

---

# 18. Local Authorization

Authorization for remediation must not exist only in Zabbix.

Each monitored host must have a local security policy.

Recommended configuration file:

```text
/etc/zabbix-package-updates.conf
```

Example:

```ini
CHECK_ENABLED=yes
REFRESH_ENABLED=yes
APPLY_SECURITY_ENABLED=no
APPLY_ALL_ENABLED=no
AUTO_REBOOT=no
```

The configuration must be writable only by root.

Recommended permissions:

```text
root:root
0640
```

Missing or invalid remediation settings must be interpreted as disabled.

A compromised Zabbix Server must not automatically gain package-update privileges on every monitored host.

---

# 19. Automatic Remediation

Do not enable automatic package updates directly from a Zabbix trigger by default.

Avoid designs such as:

```text
Security updates detected
        |
        v
Automatically perform upgrade
```

Automatic remediation may only be considered after explicit security and operational review.

It must remain optional and locally authorized.

---

# 20. Reboots

Automatic rebooting must not be part of default behavior.

If an update requires a reboot, report it to Zabbix.

Example item:

```text
Linux: Reboot required
```

The administrator decides when the reboot occurs.

If reboot functionality is ever implemented, it must be authorized independently from package-update functionality.

---

# 21. Pre-Update Validation

If remediation is implemented, validate the system before modifying packages.

Where applicable, verify:

- package-manager availability;
- package-manager lock status;
- repository availability;
- metadata status;
- filesystem free space;
- previous incomplete package transactions;
- dependency problems;
- package-signature validation;
- local remediation policy.

Use simulation or transaction preview where supported and operationally reliable.

Potentially dangerous changes should be detected whenever practical, including:

- unexpected package removals;
- large dependency changes;
- distribution-release changes;
- held-package conflicts;
- broken package state;
- package-manager errors.

Abort safely when validation fails.

---

# 22. Package Signature Security

Never weaken native repository security.

Do not automatically use options equivalent to:

```text
--allow-unauthenticated
--nogpgcheck
trusted=yes
```

Do not disable GPG or repository/package signature verification.

Signature-validation failures must generate an explicit error.

Do not bypass signature failures to make an update succeed.

---

# 23. State, Cache, and Temporary Files

Avoid predictable temporary files in shared directories such as `/tmp`.

Prefer dedicated directories such as:

```text
/run/zabbix-package-updates/
/var/lib/zabbix-package-updates/
/var/cache/zabbix-package-updates/
```

Directories and files must have appropriate ownership and permissions.

Protect against:

- symbolic-link attacks;
- race conditions;
- insecure temporary files;
- modification by unprivileged users.

Atomic file replacement should be used for cached JSON/state files when practical.

---

# 24. Logging and Audit

Privileged operations must be auditable.

Logging should record relevant information such as:

```text
timestamp
action
host
distribution
package manager
result
duration
pending package count
updated package count
security update count
reboot required
error reason
```

Never log secrets.

Do not log:

- passwords;
- API tokens;
- private keys;
- repository credentials;
- authentication headers.

A dedicated log may be used when appropriate:

```text
/var/log/zabbix-package-updates.log
```

Monitoring-only checks should avoid excessive log volume.

---

# 25. Error Handling

Errors must be explicit and machine-readable.

Never report zero updates when the collector actually failed.

These states are different:

```text
0 updates available
```

and:

```text
unable to determine available updates
```

Example error:

```json
{
  "schema_version": 1,
  "status": "error",
  "error_code": "REPOSITORY_REFRESH_FAILED",
  "message": "Unable to refresh package repository metadata."
}
```

Use stable error codes where practical.

---

# 26. Stale Data Detection

The template must detect outdated package information.

Expose timestamps such as:

```text
last_refresh
last_check
```

Provide a configurable stale-data threshold.

Example:

```text
{$PACKAGE.UPDATES.MAX.AGE}
```

Stale data must not be presented as current data.

---

# 27. Security Update Detection

Where supported by the distribution, distinguish regular updates from security updates.

Do not return a false zero when the distribution cannot reliably classify security updates.

Use an explicit state such as:

```text
unknown
unsupported
```

Accuracy is more important than always returning a numeric value.

---

# 28. Reboot Detection

Where supported, detect whether the operating system requires a reboot.

The implementation must be distribution-specific.

Do not infer reboot requirements merely because updates are pending.

Return an explicit unknown/unsupported state where reliable detection is unavailable.

---

# 29. Zabbix Template Requirements

Both Zabbix 7.0 and Zabbix 8.0 templates should contain, where appropriate:

## Master item

The normalized collector JSON.

## Dependent items

At minimum:

```text
Collector status
Available package updates
Available security updates
Package manager
Linux distribution
Linux distribution version
Reboot required
Last package check
Last repository refresh
```

Additional items may be added only when they provide useful operational value without excessive database growth.

All template content must remain in English.

---

# 30. Zabbix Triggers

Recommended trigger categories include:

```text
Security updates available
Package updates available
Reboot required
Package update information is stale
Package update collector failed
Repository metadata refresh failed
```

Trigger severities must be conservative and documented.

Do not classify normal package availability as a disaster-level condition.

---

# 31. Zabbix Macros

Use macros for administrator-configurable monitoring policy.

Examples:

```text
{$PACKAGE.UPDATES.ENABLED}
{$PACKAGE.UPDATES.MAX.AGE}
{$PACKAGE.UPDATES.WARN}
{$PACKAGE.UPDATES.SECURITY.WARN}
{$PACKAGE.UPDATES.REBOOT.WARN}
```

Macro names must be in English.

Do not hard-code policies that reasonably vary by host or environment.

---

# 32. Low-Level Discovery

Do not create one permanent Zabbix item for every pending package unless a clear technical justification exists.

Pending packages are transient and can create unnecessary item churn and database growth.

Prefer:

- aggregate items;
- normalized JSON;
- dependent items;
- a textual/JSON package list.

LLD must only be introduced after evaluating its impact on:

- item counts;
- history;
- trends;
- database size;
- housekeeping;
- performance.

---

# 33. Performance

The project must be suitable for environments with hundreds of Linux hosts.

Avoid designs in which every host creates hundreds of temporary Zabbix items.

Avoid repeated execution of expensive package-manager operations.

Use caching where appropriate.

Collector execution must be bounded and must not remain blocked indefinitely.

---

# 34. Timeouts

External package-manager commands must have controlled execution time.

Repository or network problems must not leave the collector blocked indefinitely.

Timeout failures must produce an explicit error/status.

Do not solve design problems simply by setting excessively large Zabbix Agent timeouts.

---

# 35. Dependencies

Minimize external dependencies.

Prefer:

- shell;
- standard Linux utilities;
- native package-manager tools;
- Zabbix Agent or Zabbix Agent 2.

Avoid requiring Python, Perl, Node.js, or additional frameworks unless there is a documented technical need.

Do not add a dependency merely for convenience when a simple auditable implementation is available with standard system tools.

---

# 36. Installation

Installation must be predictable, auditable, and idempotent where practical.

The installer must deploy:

```text
scripts/zabbix-package-updates
```

to:

```text
/usr/local/scripts/zabbix-package-updates
```

The installer should:

```text
✓ create /usr/local/scripts when required
✓ install the collector
✓ enforce root ownership
✓ enforce secure permissions
✓ install the local configuration when required
✓ install the restricted sudoers rule when required
✓ validate sudoers before considering installation successful
✓ install the Agent integration file when required
✓ test collector execution
✓ validate returned JSON
✓ test execution as the zabbix account
```

Do not silently modify unrelated operating-system configuration.

Before changing an existing configuration file:

- inspect its current state;
- back it up when appropriate;
- make the smallest required change.

Running the installer repeatedly must not corrupt configuration.

---

# 37. Uninstallation

Provide a documented method to remove the project cleanly.

Managed files may include:

```text
/usr/local/scripts/zabbix-package-updates
/etc/zabbix-package-updates.conf
/etc/sudoers.d/zabbix-package-updates
```

and the project-specific Zabbix Agent integration file.

Do not remove administrator-created configuration, shared directories, or historical logs without explicit action.

Do not remove `/usr/local/scripts` merely because this project created it if other files are present.

---

# 38. Required Repository Structure

Use the following project structure:

```text
zabbix-package-updates/
├── AGENTS.md
├── README.md
├── LICENSE
├── CHANGELOG.md
│
├── templates/
│   ├── 7.0/
│   │   └── template_linux_package_updates.yaml
│   └── 8.0/
│       └── template_linux_package_updates.yaml
│
├── scripts/
│   └── zabbix-package-updates
│
├── config/
│   ├── zabbix-package-updates.conf.example
│   ├── sudoers.example
│   └── userparameter.conf
│
├── install/
│   ├── install.sh
│   └── uninstall.sh
│
├── docs/
│   ├── instalacao.md
│   ├── configuracao.md
│   ├── seguranca.md
│   ├── arquitetura.md
│   ├── troubleshooting.md
│   └── compatibilidade.md
│
└── tests/
    ├── fixtures/
    └── ...
```

Repository code/directory naming stays in English.

Documentation filenames may be Portuguese when they are intended for Brazilian Portuguese readers.

---

# 39. README Requirements

`README.md` must be written in Brazilian Portuguese.

It must contain at least:

1. descrição do projeto;
2. recursos;
3. distribuições suportadas;
4. versões suportadas do Zabbix;
5. arquitetura;
6. requisitos;
7. instalação;
8. localização do coletor em `/usr/local/scripts` e a justificativa arquitetural;
9. integração com Zabbix Agent/Agent 2;
10. configuração;
11. importação dos templates 7.0 e 8.0;
12. segurança;
13. troubleshooting básico;
14. limitações conhecidas;
15. status do projeto;
16. licença.

The README must explicitly state in Portuguese that the collector is not a Zabbix Server/Proxy external check and therefore is intentionally not installed in the Zabbix `ExternalScripts` directory.

---

# 40. Documentation Requirements

At minimum, the Brazilian Portuguese architecture and installation documentation must explain this execution flow:

```text
Zabbix Server
      |
      | standard Zabbix Agent communication
      v
Zabbix Agent / Agent 2
      |
      | restricted local invocation
      v
sudo -n /usr/local/scripts/zabbix-package-updates
      |
      v
native Linux package manager
      |
      v
normalized JSON
```

Documentation must clearly distinguish this from:

```text
Zabbix Server/Proxy -> External Check -> ExternalScripts
```

Do not use these two mechanisms interchangeably in documentation.

---

# 41. CHANGELOG

Use semantic versioning where practical.

Example:

```text
0.1.0
0.2.0
1.0.0
```

User-facing changelog documentation may be written in Brazilian Portuguese.

Security-related changes and fixes must be clearly identified.

---

# 42. Testing

Changes affecting package detection must be tested against representative output from supported distributions.

Template changes must be tested independently with:

```text
Zabbix 7.0
Zabbix 8.0
```

A successful import alone is not sufficient.

Validate:

- template import;
- master item;
- preprocessing;
- dependent items;
- unsupported-item behavior;
- trigger expressions;
- macros;
- returned data types;
- stale-data handling;
- error handling.

The installed collector must be tested through its final path:

```sh
/usr/local/scripts/zabbix-package-updates
```

When sudo is used, test:

```sh
sudo -u zabbix sudo -n /usr/local/scripts/zabbix-package-updates
```

The test must not require an interactive password.

---

# 43. Security Review Checklist

Before accepting any change involving privileged functionality, review at least:

```text
Can untrusted input reach a shell?
Can Zabbix choose arbitrary commands?
Can Zabbix choose arbitrary executable paths?
Can the zabbix user modify the privileged collector?
Can the zabbix user modify the security policy/configuration?
Can symlinks be abused?
Can environment variables change privileged behavior?
Can package-signature verification be bypassed?
Can concurrent executions cause corruption?
Can package-manager locks be bypassed?
Can a compromised Zabbix Server obtain more privilege than intended?
Does the change increase lateral-movement capability?
```

If a design introduces unnecessary risk, redesign it.

---

# 44. Remediation Development Policy

Monitoring is the primary development target.

Recommended development order:

```text
Phase 1
Package update monitoring

Phase 2
Security update classification

Phase 3
Reboot detection

Phase 4
Multi-distribution support

Phase 5
Controlled manual remediation

Phase 6
Optional advanced remediation policies
```

Do not implement automatic remediation before monitoring is stable, tested, documented, and security-reviewed.

---

# 45. Safe Defaults

When choosing between convenience and safety, choose safety.

Examples:

```text
Missing APPLY_ALL_ENABLED
    -> disabled

Invalid remediation configuration
    -> refuse remediation

Unknown action
    -> refuse execution

Unexpected command-line arguments
    -> refuse execution

Unknown distribution
    -> report unsupported

Package-signature problem
    -> abort operation

Package-manager inconsistent
    -> abort operation

Package-manager already active
    -> do not bypass locks
```

---

# 46. Scope Control

Do not turn this project into a general remote-administration framework.

Primary scope:

```text
Linux package update monitoring
```

Optional future scope:

```text
tightly controlled package update remediation
```

Features unrelated to that purpose should normally be rejected.

---

# 47. Code Quality

Code should favor:

- readability;
- predictable behavior;
- small auditable functions;
- explicit validation;
- clear failure modes;
- minimal privilege;
- minimal dependencies;
- stable machine-readable output.

Avoid clever implementations when a simpler implementation is easier to review and secure.

Security-sensitive code must be understandable by another Linux administrator without requiring hidden assumptions.

---

# 48. Backward Compatibility

Avoid unnecessary changes to:

- item keys;
- macro names;
- JSON fields;
- configuration parameters;
- installed filesystem paths.

If a breaking change is unavoidable:

1. document it;
2. update the schema/version where applicable;
3. provide migration instructions;
4. update both Zabbix 7.0 and Zabbix 8.0 templates as needed.

---

# 49. Definition of Done

A feature is not complete merely because the code works.

A feature is complete when:

```text
[ ] implementation works
[ ] security implications were reviewed
[ ] error conditions were tested
[ ] permissions were reviewed
[ ] Zabbix 7.0 compatibility was validated
[ ] Zabbix 8.0 compatibility was validated
[ ] Brazilian Portuguese documentation was updated
[ ] examples were updated
[ ] CHANGELOG was updated when applicable
[ ] no unnecessary privileges were introduced
[ ] collector path remains consistent with /usr/local/scripts
```

---

# 50. Core Project Principle

The guiding security principle is:

> Zabbix may request information or an explicitly authorized package-update action, but it must never receive arbitrary package installation/removal capability or a general-purpose privileged execution capability.

Monitoring must remain safe by default.

Remediation must remain disabled by default.

Every privileged capability must be explicit, minimal, auditable, and locally authorized.

The host-side collector belongs in:

```text
/usr/local/scripts/zabbix-package-updates
```

because it is a locally maintained administrative collector invoked by the Zabbix Agent integration, not a Zabbix Server/Proxy external check.
