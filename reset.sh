#!/usr/bin/env bash
set -euo pipefail

FORCE=false
GLOBAL_RESET=false
CUSTOM_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --global|-g)
            GLOBAL_RESET=true
            shift
            ;;
        --dir|-d)
            if [[ -n "${2:-}" && ! "$2" =~ ^- ]]; then
                CUSTOM_DIR="$2"
                shift 2
            else
                echo "❌ Error: --dir requires a directory path argument."
                exit 1
            fi
            ;;
        --force|-f|-y)
            FORCE=true
            shift
            ;;
        --help|-h)
            echo "Usage: ./reset.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  (default)          Reset local workspace configuration (./.dsh) and artifacts"
            echo "  --global, -g       Reset global configuration (${HOME:-~}/.dsh) only"
            echo "  --dir, -d <path>   Reset custom configuration directory only"
            echo "  --force, -f, -y    Skip confirmation prompt"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
        *)
            echo "❌ Error: Unknown option '$1'. Use --help for usage."
            exit 1
            ;;
    esac
done

TARGET_MARKER="$PWD/.dsh-target"
RAW_MARKER=""
if [ -f "$TARGET_MARKER" ]; then
    IFS= read -r RAW_MARKER < "$TARGET_MARKER" || true
    # Trim only leading and trailing whitespace losslessly (preserving internal spaces)
    RAW_MARKER="${RAW_MARKER#"${RAW_MARKER%%[![:space:]]*}"}"
    RAW_MARKER="${RAW_MARKER%"${RAW_MARKER##*[![:space:]]}"}"
fi

IS_GLOBAL_MARKER=false
USER_HOME="${HOME:-$(cd ~ 2>/dev/null && pwd || echo "")}"
if [ "$RAW_MARKER" = "global" ] || [ "$RAW_MARKER" = "~/.dsh" ] || [ "$RAW_MARKER" = "${USER_HOME}/.dsh" ]; then
    IS_GLOBAL_MARKER=true
fi

# Precedence: --dir → --global → DSH_HOME → .dsh-target marker → local $PWD/.dsh
if [[ -n "$CUSTOM_DIR" ]]; then
    TARGET_DSH="$(mkdir -p "$CUSTOM_DIR" 2>/dev/null && cd "$CUSTOM_DIR" && pwd || echo "$CUSTOM_DIR")"
    IS_LOCAL_MODE=false
elif [ "$GLOBAL_RESET" = true ]; then
    TARGET_DSH="${USER_HOME}/.dsh"
    IS_LOCAL_MODE=false
elif [[ -n "${DSH_HOME:-}" ]]; then
    TARGET_DSH="$(cd "$DSH_HOME" 2>/dev/null && pwd || echo "$DSH_HOME")"
    IS_LOCAL_MODE=$([ "$TARGET_DSH" = "$PWD/.dsh" ] && echo true || echo false)
elif [ -n "$RAW_MARKER" ]; then
    if [ "$IS_GLOBAL_MARKER" = true ]; then
        # If workspace is linked to global DSH, a default reset only clears local workspace routing
        echo "ℹ️  Workspace is configured in global DSH mode (${USER_HOME}/.dsh)."
        echo "🧹 Purging local workspace routing (.dsh-target) and temporary artifacts..."
        rm -rf node_modules .dsh ./*.log "$TARGET_MARKER"
        echo "✅ Local workspace cleaned. Global store (${USER_HOME}/.dsh) was preserved."
        echo "   (To reset global configuration, explicitly run: ./reset.sh --global)"
        exit 0
    else
        # Expand leading tilde if present
        if [[ "$RAW_MARKER" == "~"* ]]; then
            EXPANDED_MARKER="${USER_HOME}${RAW_MARKER#\~}"
        else
            EXPANDED_MARKER="$RAW_MARKER"
        fi
        TARGET_DSH="$(cd "$EXPANDED_MARKER" 2>/dev/null && pwd || echo "$EXPANDED_MARKER")"
        IS_LOCAL_MODE=$([ "$TARGET_DSH" = "$PWD/.dsh" ] && echo true || echo false)
    fi
else
    TARGET_DSH="$PWD/.dsh"
    IS_LOCAL_MODE=true
fi

# Safety check against dangerous recursive targets
REAL_TARGET="$(cd "$TARGET_DSH" 2>/dev/null && pwd || echo "$TARGET_DSH")"
if [[ "$REAL_TARGET" == "/" || "$REAL_TARGET" == "$PWD" || "$REAL_TARGET" == "/tmp" || "$REAL_TARGET" == "/var" || "$REAL_TARGET" == "/usr" || "$REAL_TARGET" == "/etc" || ( -n "$USER_HOME" && "$REAL_TARGET" == "$USER_HOME" ) ]]; then
    echo "❌ Safety Abort: Refusing to reset dangerous target directory '${REAL_TARGET}'."
    exit 1
fi

# Installation-owned sentinel verification: ensure target is an authentic DSH directory before deleting
if [ -d "$REAL_TARGET" ]; then
    if [ ! -f "$REAL_TARGET/cordis.patch.yml" ] && \
       [ ! -f "$REAL_TARGET/.credentials.yaml" ] && \
       [ ! -f "$REAL_TARGET/settings.yaml" ] && \
       [ ! -f "$REAL_TARGET/dsh.pid" ] && \
       [ ! -d "$REAL_TARGET/profiles" ]; then
        echo "❌ Safety Abort: Directory '${REAL_TARGET}' does not appear to be a valid DSH installation."
        echo "   (Missing cordis.patch.yml, .credentials.yaml, settings.yaml, dsh.pid, or profiles/)"
        exit 1
    fi
fi

# If target directory doesn't exist in local mode and no local artifacts exist
if [ "$IS_LOCAL_MODE" = true ] && [ ! -d "$TARGET_DSH" ] && [ ! -d "node_modules" ] && [ ! -f "$TARGET_MARKER" ]; then
    echo "ℹ️  No local DSH workspace configuration (./.dsh) or node_modules found in $PWD."
    echo "   Nothing to reset locally. (To reset global configuration, run: ./reset.sh --global)"
    exit 0
fi

echo "=========================================================================="
echo "    DEEPSEEK HARNESS (DSH) COMPLETE RESET & CLEAN SLATE                   "
echo "=========================================================================="
echo ""
echo "⚠️  WARNING: This will perform the following actions:"
echo "   1. Gracefully terminate active DSH background processes on port ${DSH_PORT:-${PORT:-3080}}"
echo "   2. Wipe target configuration store (${REAL_TARGET})"
if [ "$IS_LOCAL_MODE" = true ]; then
    echo "   3. Purge local workspace artifacts (node_modules, caches, logs)"
fi
echo ""

if [ "$FORCE" = false ]; then
    read -rp "Are you sure you want to proceed with reset? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "❌ Reset cancelled."
        exit 0
    fi
fi

is_dsh_process() {
    local pid="$1"
    if [[ ! "$pid" =~ ^[0-9]+$ ]] || [ "$pid" -le 1 ]; then
        return 1
    fi
    if ! kill -0 "$pid" 2>/dev/null; then
        return 1
    fi
    local cmd
    cmd="$(ps -p "$pid" -o command= 2>/dev/null || ps -p "$pid" -o args= 2>/dev/null || true)"
    if [[ "$cmd" =~ dsh || "$cmd" =~ @deepseek-ai/dsh || "$cmd" =~ dsh-tui || "$cmd" =~ dsh-web || "$cmd" =~ dsh-cli || "$cmd" =~ dsh-headless ]]; then
        return 0
    fi
    return 1
}

kill_pid_safely() {
    local pid="$1"
    if is_dsh_process "$pid"; then
        kill -15 "$pid" 2>/dev/null || true
        sleep 0.3
        if kill -0 "$pid" 2>/dev/null; then
            kill -9 "$pid" 2>/dev/null || true
        fi
    fi
}

echo ""
echo "🛑 [1/3] Terminating active DSH processes on target port..."
TARGET_PORT="${DSH_PORT:-${PORT:-3080}}"
if command -v lsof >/dev/null 2>&1; then
    PIDS="$(lsof -ti ":${TARGET_PORT}" 2>/dev/null || true)"
    if [ -n "$PIDS" ]; then
        for pid in $PIDS; do
            kill_pid_safely "$pid"
        done
    fi
    echo "✅ Active DSH processes on port ${TARGET_PORT} terminated."
else
    echo "ℹ️  'lsof' not found — skipped port inspection."
fi

if [ -f "${REAL_TARGET}/dsh.pid" ]; then
    PID="$(cat "${REAL_TARGET}/dsh.pid" 2>/dev/null || true)"
    if [[ "$PID" =~ ^[0-9]+$ ]] && [ "$PID" -gt 1 ]; then
        kill_pid_safely "$PID"
    fi
    rm -f "${REAL_TARGET}/dsh.pid"
fi

echo "🧹 [2/3] Removing configuration directory: ${REAL_TARGET}..."
rm -rf "${REAL_TARGET}"
echo "✅ Configuration purged."

if [ "$IS_LOCAL_MODE" = true ]; then
    echo "🗑️  [3/3] Cleaning local workspace artifacts (node_modules, caches, logs)..."
    rm -rf node_modules .dsh ./*.log "$TARGET_MARKER"
    echo "✅ Local workspace cleaned."
else
    # Only remove target marker if the reset target actually matched the marker
    if [ -f "$TARGET_MARKER" ]; then
        RESOLVED_MARKER="${RAW_MARKER}"
        if [[ "$RESOLVED_MARKER" == "~"* ]]; then
            RESOLVED_MARKER="${USER_HOME}${RESOLVED_MARKER#\~}"
        fi
        RESOLVED_MARKER_PATH="$(cd "$RESOLVED_MARKER" 2>/dev/null && pwd || echo "$RESOLVED_MARKER")"
        if [ "$RESOLVED_MARKER_PATH" = "$REAL_TARGET" ] || [ "$IS_GLOBAL_MARKER" = true ]; then
            rm -f "$TARGET_MARKER"
        fi
    fi
    echo "🗑️  [3/3] Target configuration reset complete."
fi

echo ""
echo "✨ Reset complete! Specified target has been wiped."
echo "➡️ To reinstall and reconfigure, run: ./setup-dsh.sh"
echo "=========================================================================="
