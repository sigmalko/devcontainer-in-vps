#!/usr/bin/env bash
set -uo pipefail

export HOME=/root
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

readonly CLAUDE_BIN=/home/vscode/.local/bin/claude
readonly LOG_FILE=/var/log/devcontainer-cli-updates.log
readonly MAX_LOG_LINES=5000

log() {
    printf '[cli-update] %s %s\n' "$(date --iso-8601=seconds)" "$*"
}

version_of() {
    timeout 60 "$@" 2>/dev/null | head -n 1 || true
}

update_claude() {
    local before rc after
    if [ ! -x "${CLAUDE_BIN}" ]; then
        log "Claude update skipped: ${CLAUDE_BIN} is missing"
        return 1
    fi

    before="$(version_of runuser -u vscode -- env HOME=/home/vscode \
        PATH=/home/vscode/.local/bin:/usr/local/bin:/usr/bin:/bin "${CLAUDE_BIN}" --version)"
    log "Claude version before update: ${before:-unknown}"
    if timeout 15m runuser -u vscode -- env HOME=/home/vscode \
        PATH=/home/vscode/.local/bin:/usr/local/bin:/usr/bin:/bin "${CLAUDE_BIN}" update; then
        rc=0
    else
        rc=$?
    fi
    after="$(version_of runuser -u vscode -- env HOME=/home/vscode \
        PATH=/home/vscode/.local/bin:/usr/local/bin:/usr/bin:/bin "${CLAUDE_BIN}" --version)"
    log "Claude version after update: ${after:-unknown}; rc=${rc}"
    return "${rc}"
}

update_codex() {
    local before rc after
    before="$(version_of codex --version)"
    log "Codex version before update: ${before:-not installed}"
    if timeout 15m npm install --global @openai/codex@latest; then
        rc=0
    else
        rc=$?
    fi
    after="$(version_of codex --version)"
    log "Codex version after update: ${after:-unknown}; rc=${rc}"
    return "${rc}"
}

trim_log() {
    local lines tmp
    [ -f "${LOG_FILE}" ] || return 0
    lines="$(wc -l <"${LOG_FILE}" 2>/dev/null || echo 0)"
    [ "${lines}" -gt "${MAX_LOG_LINES}" ] || return 0
    tmp="$(mktemp /var/log/.devcontainer-cli-updates.XXXXXX)" || return 0
    if tail -n "${MAX_LOG_LINES}" "${LOG_FILE}" >"${tmp}"; then
        cat "${tmp}" >"${LOG_FILE}"
    fi
    rm -f "${tmp}"
}

exec 9>/run/lock/devcontainer-cli-update.lock
if ! flock -n 9; then
    log "Update skipped: another run holds the lock"
    exit 0
fi

log "Starting scheduled CLI updates"
overall_rc=0
update_claude || overall_rc=1
update_codex || overall_rc=1
log "Scheduled CLI updates finished: rc=${overall_rc}"
trim_log
exit "${overall_rc}"
