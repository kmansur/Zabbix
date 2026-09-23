#!/usr/bin/env bash
#
# uninstall.sh
#
# Removes the executable integration installed by zabbix-package-updates.
# Local configuration, cache, backups, and logs are preserved.
#

set -euo pipefail

PATH='/usr/sbin:/usr/bin:/sbin:/bin'
export PATH
LC_ALL='C'
LANG='C'
export LC_ALL LANG
umask 027

readonly TARGET_COLLECTOR='/usr/local/scripts/zabbix-package-updates'
readonly TARGET_SUDOERS='/etc/sudoers.d/zabbix-package-updates'

info() {
    printf '==> %s\n' "$*"
}

warn() {
    printf 'WARNING: %s\n' "$*" >&2
}

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

service_is_active() {
    command -v systemctl >/dev/null 2>&1 || return 1
    systemctl is-active --quiet "$1"
}

reload_if_active() {
    local service=$1
    local binary=$2
    local config=$3

    service_is_active "${service}" || return 0
    command -v "${binary}" >/dev/null 2>&1 || return 0
    [[ -f "${config}" ]] || return 0

    if "${binary}" -c "${config}" -R userparameter_reload >/dev/null 2>&1; then
        info "Reloaded UserParameters for ${service}."
    else
        warn "Unable to reload UserParameters for ${service}; restarting the service."
        systemctl restart "${service}" || warn "Unable to restart ${service}."
    fi
}

main() {
    (( $# == 0 )) || die 'This uninstaller does not accept command-line arguments.'
    (( EUID == 0 )) || die 'This uninstaller must be run as root.'

    local snippet
    for snippet in \
        /etc/zabbix/zabbix_agent2.d/zabbix-package-updates.conf \
        /etc/zabbix/zabbix_agentd.d/zabbix-package-updates.conf
    do
        if [[ -f "${snippet}" && ! -L "${snippet}" ]]; then
            rm -f -- "${snippet}"
            info "Removed ${snippet}"
        elif [[ -L "${snippet}" ]]; then
            warn "Refusing to remove symbolic link: ${snippet}"
        fi
    done

    if [[ -f "${TARGET_SUDOERS}" && ! -L "${TARGET_SUDOERS}" ]]; then
        rm -f -- "${TARGET_SUDOERS}"
        info "Removed ${TARGET_SUDOERS}"
    elif [[ -L "${TARGET_SUDOERS}" ]]; then
        warn "Refusing to remove symbolic link: ${TARGET_SUDOERS}"
    fi

    if command -v visudo >/dev/null 2>&1; then
        visudo -c >/dev/null || warn 'Global sudoers validation failed after removal.'
    fi

    if [[ -f "${TARGET_COLLECTOR}" && ! -L "${TARGET_COLLECTOR}" ]]; then
        rm -f -- "${TARGET_COLLECTOR}"
        info "Removed ${TARGET_COLLECTOR}"
    elif [[ -L "${TARGET_COLLECTOR}" ]]; then
        warn "Refusing to remove symbolic link: ${TARGET_COLLECTOR}"
    fi

    reload_if_active zabbix-agent2 zabbix_agent2 /etc/zabbix/zabbix_agent2.conf
    reload_if_active zabbix-agent zabbix_agentd /etc/zabbix/zabbix_agentd.conf

    printf '\nUninstallation completed.\n'
    printf 'Preserved intentionally:\n'
    printf '  /etc/zabbix-package-updates.conf\n'
    printf '  /var/cache/zabbix-package-updates/\n'
    printf '  /var/backups/zabbix-package-updates/\n'
    printf '  /var/log/zabbix-package-updates.log (if present)\n'
}

main "$@"
