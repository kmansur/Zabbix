#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
COLLECTOR="${PROJECT_ROOT}/scripts/zabbix-package-updates"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_eq() {
    local expected=$1 actual=$2 message=$3
    [[ "$expected" == "$actual" ]] || fail "$message: expected '$expected', got '$actual'"
}

bash -n "$COLLECTOR"

# The collector has a source guard so helper functions can be tested without
# executing privileged package-manager operations.
# shellcheck source=../scripts/zabbix-package-updates
source "$COLLECTOR"

assert_eq 'a\"b\\c\n' "$(json_escape $'a"b\\c\n')" 'json_escape'
assert_eq 'yes' "$(bool true)" 'bool true'
assert_eq 'no' "$(bool false)" 'bool false'

if grep -En '(^|[[:space:]])(eval|sh[[:space:]]+-c|bash[[:space:]]+-c)([[:space:]]|$)' "$COLLECTOR"; then
    fail 'forbidden dynamic shell execution pattern found'
fi

if grep -Fq 'system.run' "$COLLECTOR"; then
    fail 'system.run must not be used by this project'
fi

if grep -Eq '(apt(-get)?|dnf5?|yum|zypper)[[:space:]]+(install|remove|erase|upgrade|dist-upgrade|full-upgrade)' "$COLLECTOR"; then
    fail 'package installation/removal/upgrade command found in monitoring-only collector'
fi

printf 'All core tests passed.\n'
