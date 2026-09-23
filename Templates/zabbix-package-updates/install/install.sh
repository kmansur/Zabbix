#!/usr/bin/env bash
# Secure installer for zabbix-package-updates.
# It does not install operating-system packages.

set -euo pipefail
PATH='/usr/sbin:/usr/bin:/sbin:/bin'
LC_ALL=C
LANG=C
export PATH LC_ALL LANG
umask 027

readonly TARGET_DIR='/usr/local/scripts'
readonly TARGET_COLLECTOR='/usr/local/scripts/zabbix-package-updates'
readonly TARGET_CONFIG='/etc/zabbix-package-updates.conf'
readonly TARGET_SUDOERS='/etc/sudoers.d/zabbix-package-updates'

info() { printf '==> %s\n' "$*"; }
warn() { printf 'WARNING: %s\n' "$*" >&2; }
die() { printf 'ERROR: %s\n' "$*" >&2; exit 1; }

secure_dir() {
    local dir=$1 owner mode
    [[ ! -L "$dir" ]] || die "Refusing symbolic-link directory: $dir"
    install -d -o root -g root -m 0755 "$dir"
    owner=$(stat -c '%u' "$dir"); mode=$(stat -c '%A' "$dir")
    [[ $owner == 0 && ${mode:5:1} != w && ${mode:8:1} != w ]] || \
        die "$dir must be root-owned and not group/other writable."
}

backup_file() {
    local file=$1 backup_dir='/var/backups/zabbix-package-updates'
    [[ -e "$file" ]] || return 0
    [[ ! -L "$file" ]] || die "Refusing to overwrite symbolic link: $file"
    install -d -o root -g root -m 0700 "$backup_dir"
    cp -a -- "$file" "$backup_dir/$(basename "$file").$(date +%Y%m%d%H%M%S)"
}

find_source_root() {
    local root
    root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
    [[ -f "$root/scripts/zabbix-package-updates" ]] || die 'Collector source file was not found.'
    [[ -f "$root/config/zabbix-package-updates.conf.example" ]] || die 'Configuration example was not found.'
    [[ -f "$root/config/sudoers.example" ]] || die 'sudoers example was not found.'
    [[ -f "$root/config/userparameter.conf" ]] || die 'UserParameter example was not found.'
    printf '%s' "$root"
}

detect_agent() {
    local a2_conf='/etc/zabbix/zabbix_agent2.conf' a_conf='/etc/zabbix/zabbix_agentd.conf'
    local a2_dir='/etc/zabbix/zabbix_agent2.d' a_dir='/etc/zabbix/zabbix_agentd.d'

    if [[ -f "$a2_conf" && ! -f "$a_conf" ]]; then
        AGENT_CONF=$a2_conf; AGENT_DIR=$a2_dir; AGENT_BIN=$(command -v zabbix_agent2 || true); AGENT_SERVICE=zabbix-agent2
    elif [[ -f "$a_conf" && ! -f "$a2_conf" ]]; then
        AGENT_CONF=$a_conf; AGENT_DIR=$a_dir; AGENT_BIN=$(command -v zabbix_agentd || true); AGENT_SERVICE=zabbix-agent
    elif [[ -f "$a2_conf" && -f "$a_conf" ]]; then
        if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet zabbix-agent2; then
            AGENT_CONF=$a2_conf; AGENT_DIR=$a2_dir; AGENT_BIN=$(command -v zabbix_agent2 || true); AGENT_SERVICE=zabbix-agent2
        elif command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet zabbix-agent; then
            AGENT_CONF=$a_conf; AGENT_DIR=$a_dir; AGENT_BIN=$(command -v zabbix_agentd || true); AGENT_SERVICE=zabbix-agent
        else
            die 'Both Zabbix Agent and Agent 2 configurations exist and the active agent cannot be determined.'
        fi
    else
        die 'Zabbix Agent or Zabbix Agent 2 is required before installing this project.'
    fi

    [[ -n "$AGENT_BIN" ]] || die 'The selected Zabbix Agent binary was not found in PATH.'
    [[ -d "$AGENT_DIR" ]] || install -d -o root -g root -m 0755 "$AGENT_DIR"
}

validate_agent_include() {
    local escaped=${AGENT_DIR//\//\\/}
    if ! grep -Eq "^[[:space:]]*Include[[:space:]]*=[[:space:]]*${escaped}/?\\*\\.conf[[:space:]]*$" "$AGENT_CONF"; then
        die "The selected agent configuration does not include ${AGENT_DIR}/*.conf."
    fi
}

install_atomic() {
    local source=$1 target=$2 mode=$3 dir tmp
    dir=${target%/*}
    tmp=$(mktemp "${dir}/.zpu.XXXXXX")
    install -o root -g root -m "$mode" "$source" "$tmp"
    mv -f -- "$tmp" "$target"
}

install_sudoers() {
    command -v sudo >/dev/null 2>&1 || die 'sudo is required.'
    command -v visudo >/dev/null 2>&1 || die 'visudo is required.'
    [[ -d /etc/sudoers.d ]] || die '/etc/sudoers.d is unavailable.'
    grep -Eq '^[[:space:]]*[@#]includedir[[:space:]]+/etc/sudoers\.d([[:space:]]|$)' /etc/sudoers || \
        die '/etc/sudoers does not include /etc/sudoers.d.'

    local tmp
    tmp=$(mktemp /etc/sudoers.d/.zpu.XXXXXX)
    printf '%s\n' 'zabbix ALL=(root) NOPASSWD: /usr/local/scripts/zabbix-package-updates ""' > "$tmp"
    chmod 0440 "$tmp"; chown root:root "$tmp"
    visudo -cf "$tmp" >/dev/null || { rm -f "$tmp"; die 'Generated sudoers rule failed validation.'; }
    backup_file "$TARGET_SUDOERS"
    mv -f -- "$tmp" "$TARGET_SUDOERS"
    visudo -c >/dev/null || die 'Global sudoers validation failed after installation.'
}

reload_agent() {
    if "$AGENT_BIN" -c "$AGENT_CONF" -R userparameter_reload >/dev/null 2>&1; then
        info 'UserParameters reloaded.'
        return 0
    fi
    if command -v systemctl >/dev/null 2>&1 && systemctl is-active --quiet "$AGENT_SERVICE"; then
        systemctl restart "$AGENT_SERVICE"
        info "Restarted $AGENT_SERVICE."
    else
        warn 'Agent is not active; start/reload it before using the template.'
    fi
}

main() {
    (( $# == 0 )) || die 'This installer does not accept command-line arguments.'
    (( EUID == 0 )) || die 'Run this installer as root.'

    local root snippet
    root=$(find_source_root)
    detect_agent
    validate_agent_include
    secure_dir "$TARGET_DIR"

    bash -n "$root/scripts/zabbix-package-updates" || die 'Collector syntax validation failed.'
    backup_file "$TARGET_COLLECTOR"
    install_atomic "$root/scripts/zabbix-package-updates" "$TARGET_COLLECTOR" 0755

    if [[ ! -e "$TARGET_CONFIG" ]]; then
        install_atomic "$root/config/zabbix-package-updates.conf.example" "$TARGET_CONFIG" 0640
    else
        [[ -f "$TARGET_CONFIG" && ! -L "$TARGET_CONFIG" ]] || die 'Existing configuration is not a safe regular file.'
        chown root:root "$TARGET_CONFIG"
        chmod 0640 "$TARGET_CONFIG"
        info 'Existing local configuration preserved.'
    fi

    install_sudoers

    snippet="$AGENT_DIR/zabbix-package-updates.conf"
    backup_file "$snippet"
    install_atomic "$root/config/userparameter.conf" "$snippet" 0644

    "$AGENT_BIN" -c "$AGENT_CONF" -T >/dev/null || die 'Zabbix Agent configuration validation failed.'

    if ! sudo -u zabbix -- sudo -n -- "$TARGET_COLLECTOR" >/dev/null; then
        die 'Collector test through the restricted sudo rule failed.'
    fi

    reload_agent
    info "Installed collector: $TARGET_COLLECTOR"
    info "Installed UserParameter: $snippet"
    info 'No packages were installed, removed or upgraded by this installer.'
}

main "$@"
