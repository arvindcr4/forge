#!/usr/bin/env bash
# Forge installer (arvindcr4/forge fork).
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/arvindcr4/forge/main/install.sh | bash
#
# Environment overrides:
#   FORGE_REPO         GitHub owner/repo to install from   (default: arvindcr4/forge)
#   FORGE_REF          Branch, tag, or commit to install   (default: main)
#   FORGE_NO_SHELL     Set to 1 to skip shell-plugin setup (default: unset)
#   FORGE_SHELL        Override shell auto-detection (zsh|fish|bash)
#
# What this does:
#   1. Verifies a Rust toolchain is available (cargo, rustc).
#   2. Builds and installs the `forge` binary via `cargo install --git`.
#   3. Detects your interactive shell and installs the matching plugin:
#        - zsh   via `forge setup` (updates ~/.zshrc, makes a backup)
#        - fish  via a clone into ~/.local/share/forge/shell-plugin-fish
#                and a loader at ~/.config/fish/conf.d/forge.fish
#        - bash / pwsh / cmd: prints guidance; no auto-install (no plugin).

set -euo pipefail

FORGE_REPO="${FORGE_REPO:-arvindcr4/forge}"
FORGE_REF="${FORGE_REF:-main}"
FORGE_GIT_URL="https://github.com/${FORGE_REPO}.git"

log()  { printf '\033[1;36m[forge-install]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[forge-install]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[forge-install]\033[0m %s\n' "$*" >&2; }

require_cargo() {
    if ! command -v cargo >/dev/null 2>&1; then
        err "cargo not found. Install Rust first: https://rustup.rs"
        err "  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
        exit 1
    fi
    log "cargo: $(cargo --version)"
}

install_binary() {
    log "Installing forge from ${FORGE_GIT_URL} (ref: ${FORGE_REF})"
    cargo install \
        --git "${FORGE_GIT_URL}" \
        --branch "${FORGE_REF}" \
        --bin forge \
        --locked \
        --force \
        forge_main
    if ! command -v forge >/dev/null 2>&1; then
        err "forge installed but not on PATH. Add \$HOME/.cargo/bin to PATH."
        exit 1
    fi
    log "forge: $(forge --version 2>/dev/null || echo unknown)"
}

detect_shell() {
    if [ -n "${FORGE_SHELL:-}" ]; then
        printf '%s' "${FORGE_SHELL}"
        return
    fi
    case "${SHELL:-}" in
        */zsh)  printf 'zsh' ;;
        */fish) printf 'fish' ;;
        */bash) printf 'bash' ;;
        *)      printf 'unknown' ;;
    esac
}

setup_zsh() {
    log "Setting up zsh integration via 'forge setup'"
    forge setup || warn "forge setup exited non-zero — check the doctor output above"
}

setup_fish() {
    local plugin_dir="${HOME}/.local/share/forge/shell-plugin-fish"
    local conf_dir="${HOME}/.config/fish/conf.d"
    local loader="${conf_dir}/forge.fish"

    log "Setting up fish integration"
    mkdir -p "${HOME}/.local/share/forge" "${conf_dir}"

    if [ -d "${plugin_dir}/.git" ]; then
        log "Updating existing fish plugin checkout at ${plugin_dir}"
        git -C "${plugin_dir}" pull --ff-only --quiet || warn "git pull failed; continuing"
    elif [ -e "${plugin_dir}" ] || [ -L "${plugin_dir}" ]; then
        log "Existing path at ${plugin_dir} (symlink or non-git dir); leaving in place"
    else
        log "Cloning fish plugin into ${plugin_dir}"
        local tmp
        tmp="$(mktemp -d)"
        git clone --depth 1 --branch "${FORGE_REF}" "${FORGE_GIT_URL}" "${tmp}" >/dev/null
        mv "${tmp}/shell-plugin-fish" "${plugin_dir}"
        rm -rf "${tmp}"
    fi

    if [ -f "${loader}" ] && grep -q '>>> forge initialize >>>' "${loader}"; then
        log "Fish loader already present at ${loader}"
    else
        log "Writing fish loader to ${loader}"
        cat > "${loader}" <<'FISH'
# >>> forge initialize >>>
# Loaded by fish at interactive startup.
# Edit ~/.local/share/forge/shell-plugin-fish for plugin changes.
if status is-interactive
    set -l forge_plugin_dir ~/.local/share/forge/shell-plugin-fish
    if test -f $forge_plugin_dir/forge.plugin.fish
        source $forge_plugin_dir/forge.plugin.fish
    end
    if test -f $forge_plugin_dir/forge.theme.fish
        source $forge_plugin_dir/forge.theme.fish
    end
end
# <<< forge initialize <<<
FISH
    fi
    log "Fish setup complete. Open a new fish shell to activate."
}

setup_bash() {
    warn "No bash plugin ships with forge. Skipping shell integration."
    warn "You can still use 'forge' as a CLI; the ':' prefix system requires zsh or fish."
}

setup_unknown() {
    warn "Could not detect a supported interactive shell from \$SHELL=${SHELL:-<unset>}."
    warn "Run one of these manually:"
    warn "  zsh users  : forge setup"
    warn "  fish users : re-run this installer with FORGE_SHELL=fish"
}

setup_shell() {
    if [ "${FORGE_NO_SHELL:-0}" = "1" ]; then
        log "FORGE_NO_SHELL=1 — skipping shell-plugin setup."
        return
    fi
    local sh
    sh="$(detect_shell)"
    log "Detected shell: ${sh}"
    case "${sh}" in
        zsh)     setup_zsh ;;
        fish)    setup_fish ;;
        bash)    setup_bash ;;
        *)       setup_unknown ;;
    esac
}

main() {
    log "Forge installer — arvindcr4/forge fork"
    require_cargo
    install_binary
    setup_shell
    log "Done. Open a new shell, then run: forge"
}

main "$@"
