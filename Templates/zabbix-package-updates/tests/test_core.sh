#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
COLLECTOR="${PROJECT_ROOT}/scripts/zabbix-package-updates"
INSTALLER="${PROJECT_ROOT}/install/install.sh"
UNINSTALLER="${PROJECT_ROOT}/install/uninstall.sh"
USERPARAMETER="${PROJECT_ROOT}/config/userparameter.conf"
SUDOERS_EXAMPLE="${PROJECT_ROOT}/config/sudoers.example"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_eq() {
    local expected=$1 actual=$2 message=$3
    [[ "${expected}" == "${actual}" ]] ||
        fail "${message}: expected '${expected}', got '${actual}'"
}

for script in "${COLLECTOR}" "${INSTALLER}" "${UNINSTALLER}"; do
    bash -n "${script}" || fail "bash syntax check failed: ${script}"
done

# The collector uses a source guard, so helper functions can be tested without
# executing privileged package-manager operations.
# shellcheck source=../scripts/zabbix-package-updates
source "${COLLECTOR}"

assert_eq 'a\"b\\c\n' "$(json_escape $'a"b\\c\n')" 'json_escape'
assert_eq 'yes' "$(parse_bool true)" 'parse_bool true'
assert_eq 'yes' "$(parse_bool YES)" 'parse_bool YES'
assert_eq 'no' "$(parse_bool false)" 'parse_bool false'
assert_eq '21600' "$(parse_positive_integer 21600)" 'positive integer parsing'

if parse_bool invalid >/dev/null 2>&1; then
    fail 'parse_bool accepted an invalid value'
fi

if parse_positive_integer 0 >/dev/null 2>&1; then
    fail 'parse_positive_integer accepted zero'
fi

if grep -En '(^|[[:space:]])(eval|sh[[:space:]]+-c|bash[[:space:]]+-c)([[:space:]]|$)' "${COLLECTOR}"; then
    fail 'forbidden dynamic shell execution pattern found'
fi

if grep -Fq 'system.run' "${COLLECTOR}" "${USERPARAMETER}"; then
    fail 'system.run must not be used by this project'
fi

if grep -Eq '(apt(-get)?|dnf5?|yum|zypper)[[:space:]]+(install|remove|erase|upgrade|dist-upgrade|full-upgrade)' "${COLLECTOR}"; then
    fail 'package installation/removal/upgrade command found in monitoring-only collector'
fi

if grep -Eq 'UserParameter=.*\[[*]' "${USERPARAMETER}"; then
    fail 'flexible UserParameter is not allowed'
fi

grep -Fq '/usr/local/scripts/zabbix-package-updates' "${USERPARAMETER}" ||
    fail 'UserParameter does not use the required collector path'

grep -Fq '/usr/local/scripts/zabbix-package-updates ""' "${SUDOERS_EXAMPLE}" ||
    fail 'sudoers example does not restrict the collector to an empty argument list'


for template in \
    "${PROJECT_ROOT}/templates/7.0/template_linux_package_updates.yaml" \
    "${PROJECT_ROOT}/templates/8.0/template_linux_package_updates.yaml"
do
    grep -q '^      groups:
 "${template}" ||
        fail "template groups block is not at template scope: ${template}"
    grep -q '^      items:
 "${template}" ||
        fail "template items block is not at template scope: ${template}"
    if grep -q '^          items:
 "${template}"; then
        fail "template items block is incorrectly nested inside groups: ${template}"
    fi
    grep -q '^      tags:
 "${template}" ||
        fail "template tags block is not at template scope: ${template}"
    grep -q '^      macros:
 "${template}" ||
        fail "template macros block is not at template scope: ${template}"
done

printf 'All core tests passed.\n'
