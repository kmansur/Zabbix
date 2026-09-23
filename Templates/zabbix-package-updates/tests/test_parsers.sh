#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
# shellcheck source=../scripts/zabbix-package-updates
source "${PROJECT_ROOT}/scripts/zabbix-package-updates"

fail() {
    printf 'FAIL: %s\n' "$*" >&2
    exit 1
}

assert_eq() {
    local expected=$1
    local actual=$2
    local message=$3
    [[ "${expected}" == "${actual}" ]] || fail "${message}: expected '${expected}', got '${actual}'"
}

setup_workdir() {
    WORK_DIR=$(mktemp -d)
    PACKAGES_FILE="${WORK_DIR}/packages.tsv"
    SECURITY_KEYS_FILE="${WORK_DIR}/security-keys.txt"
    : > "${PACKAGES_FILE}"
    : > "${SECURITY_KEYS_FILE}"
    chmod 0600 "${PACKAGES_FILE}" "${SECURITY_KEYS_FILE}"
}

cleanup_test() {
    if [[ -n "${WORK_DIR:-}" && -d "${WORK_DIR}" ]]; then
        rm -rf -- "${WORK_DIR}"
    fi
    return 0
}
trap cleanup_test EXIT

test_json_escape() {
    local output
    output=$(json_escape $'a"b\\c\n')
    assert_eq 'a\"b\\c\n' "${output}" 'json_escape'
}

test_apt_parser() {
    local fake_apt fake_dpkg count first_security second_security

    setup_workdir

    fake_apt="${WORK_DIR}/apt"
    fake_dpkg="${WORK_DIR}/dpkg-query"

    cat > "${fake_apt}" <<'EOF'
#!/bin/sh
cat <<'OUT'
Listing...
openssl/bookworm-security 3.0.17-1~deb12u3 amd64 [upgradable from: 3.0.17-1~deb12u2]
curl/bookworm 7.88.1-10+deb12u12 amd64 [upgradable from: 7.88.1-10+deb12u10]
OUT
EOF

    cat > "${fake_dpkg}" <<'EOF'
#!/bin/sh
exit 1
EOF

    chmod 0755 "${fake_apt}" "${fake_dpkg}"

    APT="${fake_apt}"
    DPKG_QUERY="${fake_dpkg}"
    TIMEOUT_BIN=$(command -v timeout)
    COMMAND_TIMEOUT=5
    SECURITY_STATUS='unknown'

    collect_apt_updates

    count=$(wc -l < "${PACKAGES_FILE}" | tr -d ' ')
    assert_eq '2' "${count}" 'APT package count'
    assert_eq 'heuristic' "${SECURITY_STATUS}" 'APT security status'

    first_security=$(awk -F '\t' 'NR==1 {print $6}' "${PACKAGES_FILE}")
    second_security=$(awk -F '\t' 'NR==2 {print $6}' "${PACKAGES_FILE}")

    assert_eq 'true' "${first_security}" 'APT security package classification'
    assert_eq 'false' "${second_security}" 'APT regular package classification'

    cleanup_test
    WORK_DIR=''
}

test_dnf5_parser() {
    local fake_dnf5 fake_rpm count first_security second_security

    setup_workdir

    fake_dnf5="${WORK_DIR}/dnf5"
    fake_rpm="${WORK_DIR}/rpm"

    cat > "${fake_dnf5}" <<'EOF'
#!/bin/sh
case " $* " in
  *" --security "*)
    printf 'openssl-libs\tx86_64\t3.2.2-6.el9_5\tbaseos\n'
    ;;
  *)
    printf 'openssl-libs\tx86_64\t3.2.2-6.el9_5\tbaseos\n'
    printf 'curl\tx86_64\t8.5.0-10.el9\tbaseos\n'
    ;;
esac
EOF

    cat > "${fake_rpm}" <<'EOF'
#!/bin/sh
case "$*" in
  *openssl-libs.x86_64*) printf '3.2.2-5.el9_5\n' ;;
  *curl.x86_64*) printf '8.5.0-9.el9\n' ;;
  *) exit 1 ;;
esac
EOF

    chmod 0755 "${fake_dnf5}" "${fake_rpm}"

    DNF5="${fake_dnf5}"
    RPM="${fake_rpm}"
    TIMEOUT_BIN=$(command -v timeout)
    COMMAND_TIMEOUT=5
    SECURITY_STATUS='unknown'

    collect_dnf5_updates

    count=$(wc -l < "${PACKAGES_FILE}" | tr -d ' ')
    assert_eq '2' "${count}" 'DNF5 package count'
    assert_eq 'supported' "${SECURITY_STATUS}" 'DNF5 security status'

    first_security=$(awk -F '\t' 'NR==1 {print $6}' "${PACKAGES_FILE}")
    second_security=$(awk -F '\t' 'NR==2 {print $6}' "${PACKAGES_FILE}")

    assert_eq 'true' "${first_security}" 'DNF5 security package classification'
    assert_eq 'false' "${second_security}" 'DNF5 regular package classification'

    cleanup_test
    WORK_DIR=''
}

main_test() {
    test_json_escape
    test_apt_parser
    test_dnf5_parser
    printf 'All parser tests passed.\n'
}

main_test
