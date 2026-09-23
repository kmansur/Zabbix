#!/usr/bin/env bash
#
# install.sh
#
# Secure installer for zabbix-package-updates.
#

set -euo pipefail

PATH='/usr/sbin:/usr/bin:/sbin:/bin'
export PATH
LC_ALL='C'
LANG='C'
export LC_ALL LANG
umask 027

readonly PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
readonly SOURCE_COLLECTOR="${PROJECT_ROOT}/scripts/zabbix-package-updates"
readonly SOURCE_CONFIG="${PROJECT_ROOT}/config/zabbix-package-updates.conf.example"
readonly SOURCE_SUDOERS="${PROJECT_ROOT}/config/sudoers.example"
readonly SOURCE_USERPARAMETER="${PROJECT_ROOT}/config/userparameter.conf"

readonly TARGET_SCRIPT_DIR='/usr/local/scripts'
readonly TARGET_COLLECTOR='/usr/local/scripts/zabbix-package-updates'
readonly TARGET_CONFIG='/etc/zabbix-package-updates.conf'
readonly TARGET_SUDOERS='/etc/sudoers.d/zabbix-package-updates'
readonly BACKUP_DIR='/var/backups/zabbix-package-updates'

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

require_regular_file() {
    local file=$1
    [[ -f "${file}" && ! -L "${file}" ]] || die "Required source file is missing or unsafe: ${file}"
}

backup_file() {
    local file=$1
    local stamp

    [[ -e "${file}" ]] || return 0
    [[ ! -L "${file}" ]] || die "Refusing to overwrite symbolic link: ${file}"

    stamp=$(date '+%Y%m%d-%H%M%S')
    install -d -o root -g root -m 0700 "${BACKUP_DIR}"
    cp -p -- "${file}" "${BACKUP_DIR}/$(basename -- "${file}").${stamp}"
    info "Backup created for ${file}"
}

install_userparameter() {
    local installed='no'
    local directory target

    for directory in \
        /etc/zabbix/zabbix_agent2.d \
        /etc/zabbix/zabbix_agentd.d
    do
        [[ -d "${directory}" && ! -L "${directory}" ]] || continue

        target="${directory}/zabbix-package-updates.conf"
        backup_file "${target}"
        install -o root -g root -m 0644 "${SOURCE_USERPARAMETER}" "${target}"
        info "Installed Agent integration: ${target}"
        installed='yes'
    done

    [[ "${installed}" == 'yes' ]] || die 'No supported Zabbix Agent include directory was found.'
}

validate_sudoers() {
    command -v visudo >/dev/null 2>&1 || die 'visudo is required to validate the restricted sudoers rule.'
    visudo -cf "${TARGET_SUDOERS}" >/dev/null || die 'The installed sudoers rule failed validation.'
}

reload_agent() {
    local reloaded='no'

    if command -v systemctl >/dev/null 2>&1; then
        if systemctl is-active --quiet zabbix-agent2 2>/dev/null; then
            if command -v zabbix_agent2 >/dev/null 2>&1 &&
               zabbix_agent2 -c /etc/zabbix/zabbix_agent2.conf -R userparameter_reload >/dev/null 2>&1; then
                info 'Reloaded Zabbix Agent 2 UserParameters.'
            else
                systemctl restart zabbix-agent2
                info 'Restarted zabbix-agent2.'
            fi
            reloaded='yes'
        fi

        if systemctl is-active --quiet zabbix-agent 2>/dev/null; then
            if command -v zabbix_agentd >/dev/null 2>&1 &&
               zabbix_agentd -c /etc/zabbix/zabbix_agentd.conf -R userparameter_reload >/dev/null 2>&1; then
                info 'Reloaded Zabbix Agent UserParameters.'
            else
                systemctl restart zabbix-agent
                info 'Restarted zabbix-agent.'
            fi
            reloaded='yes'
        fi
    fi

    [[ "${reloaded}" == 'yes' ]] || warn 'No active Zabbix Agent service was detected. Reload/restart it manually if necessary.'
}

test_collector() {
    local output

    info 'Testing collector directly as root...'
    output=$("${TARGET_COLLECTOR}") || {
        printf '%s\n' "${output}" >&2
        die 'Collector test failed.'
    }

    [[ "${output}" == \{*\} ]] || die 'Collector did not return JSON-like output.'
    printf '%s\n' "${output}" | grep -q '"schema_version":1' || die 'Collector returned an unexpected schema.'
    printf '%s\n' "${output}" | grep -q '"status":"ok"\|"status":"disabled"' || die 'Collector did not return a successful monitoring state.'

    if id zabbix >/dev/null 2>&1; then
        info 'Testing restricted execution as the zabbix account...'
        output=$(sudo -u zabbix sudo -n -- "${TARGET_COLLECTOR}") || {
            printf '%s\n' "${output}" >&2
            die 'Restricted zabbix sudo execution test failed.'
        }
        printf '%s\n' "${output}" | grep -q '"schema_version":1' || die 'Zabbix execution returned an unexpected schema.'
    else
        die 'The zabbix service account does not exist.'
    fi
}

main() {
    (( $# == 0 )) || die 'This installer does not accept command-line arguments.'
    (( EUID == 0 )) || die 'This installer must be run as root.'

    require_regular_file "${SOURCE_COLLECTOR}"
    require_regular_file "${SOURCE_CONFIG}"
    require_regular_file "${SOURCE_SUDOERS}"
    require_regular_file "${SOURCE_USERPARAMETER}"

    command -v sudo >/dev/null 2>&1 || die 'sudo is required.'
    command -v timeout >/dev/null 2>&1 || die 'timeout is required (normally provided by coreutils).'
    command -v flock >/dev/null 2>&1 || die 'flock is required (normally provided by util-linux).'
    command -v stat >/dev/null 2>&1 || die 'stat is required.'
    command -v readlink >/dev/null 2>&1 || die 'readlink is required.'

    id zabbix >/dev/null 2>&1 || die 'The zabbix service account was not found.'

    if [[ -e "${TARGET_SCRIPT_DIR}" ]]; then
        [[ -d "${TARGET_SCRIPT_DIR}" && ! -L "${TARGET_SCRIPT_DIR}" ]] ||
            die "${TARGET_SCRIPT_DIR} exists but is not a safe directory."
    else
        install -d -o root -g root -m 0755 "${TARGET_SCRIPT_DIR}"
        info "Created ${TARGET_SCRIPT_DIR}"
    fi

    local dir_owner dir_mode
    dir_owner=$(stat -c '%u' -- "${TARGET_SCRIPT_DIR}")
    dir_mode=$(stat -c '%a' -- "${TARGET_SCRIPT_DIR}")
    [[ "${dir_owner}" == '0' ]] || die "${TARGET_SCRIPT_DIR} must be owned by root."
    (( (8#${dir_mode} & 8#022) == 0 )) || die "${TARGET_SCRIPT_DIR} must not be writable by group or others."

    backup_file "${TARGET_COLLECTOR}"
    install -o root -g root -m 0755 "${SOURCE_COLLECTOR}" "${TARGET_COLLECTOR}"
    info "Installed collector: ${TARGET_COLLECTOR}"

    if [[ ! -e "${TARGET_CONFIG}" ]]; then
        install -o root -g root -m 0640 "${SOURCE_CONFIG}" "${TARGET_CONFIG}"
        info "Installed default configuration: ${TARGET_CONFIG}"
    else
        [[ -f "${TARGET_CONFIG}" && ! -L "${TARGET_CONFIG}" ]] ||
            die "Refusing unsafe existing configuration: ${TARGET_CONFIG}"
        info "Preserved existing configuration: ${TARGET_CONFIG}"
    fi

    backup_file "${TARGET_SUDOERS}"
    install -o root -g root -m 0440 "${SOURCE_SUDOERS}" "${TARGET_SUDOERS}"
    validate_sudoers
    info "Installed restricted sudoers rule: ${TARGET_SUDOERS}"

    install_userparameter

    install -d -o root -g root -m 0750 /var/cache/zabbix-package-updates
    install -d -o root -g root -m 0750 /run/zabbix-package-updates

    test_collector
    reload_agent

    printf '\nInstallation completed successfully.\n'
    printf 'Collector : %s\n' "${TARGET_COLLECTOR}"
    printf 'Config    : %s\n' "${TARGET_CONFIG}"
    printf 'Zabbix key: linux.package.updates\n'
    printf '\nNo package installation or update application capability was enabled.\n'
}

main "$@"
