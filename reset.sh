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
            echo "  --global, -g       Reset global configuration (~/.dsh) only"
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

# Precedence: --dir → --global → DSH_HOME → local $PWD/.dsh
if [[ -n "$CUSTOM_DIR" ]]; then
    TARGET_DSH="$(mkdir -p "$CUSTOM_DIR" 2>/dev/null && cd "$CUSTOM_DIR" && pwd || echo "$CUSTOM_DIR")"
    IS_LOCAL_MODE=false
elif [ "$GLOBAL_RESET" = true ]; then
    TARGET_DSH="$HOME/.dsh"
    IS_LOCAL_MODE=false
elif [[ -n "${DSH_HOME:-}" ]]; then
    TARGET_DSH="$(cd "$DSH_HOME" 2>/dev/null && pwd || echo "$DSH_HOME")"
    IS_LOCAL_MODE=$([ "$TARGET_DSH" = "$PWD/.dsh" ] && echo true || echo false)
else
    TARGET_DSH="$PWD/.dsh"
    IS_LOCAL_MODE=true
fi

# Safety check against dangerous recursive targets
REAL_TARGET="$(cd "$TARGET_DSH" 2>/dev/null && pwd || echo "$TARGET_DSH")"
if [[ "$REAL_TARGET" == "/" || "$REAL_TARGET" == "$HOME" || "$REAL_TARGET" == "/tmp" || "$REAL_TARGET" == "$PWD" || "$REAL_TARGET" == "/var" || "$REAL_TARGET" == "/usr" || "$REAL_TARGET" == "/etc" ]]; then
    echo "❌ Safety Abort: Refusing to reset dangerous target directory '${REAL_TARGET}'."
    exit 1
fi

# If target directory doesn't exist in local mode and no local artifacts exist
if [ "$IS_LOCAL_MODE" = true ] && [ ! -d "$TARGET_DSH" ] && [ ! -d "node_modules" ]; then
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

echo ""
echo "🛑 [1/3] Terminating active DSH processes on target port..."
TARGET_PORT="${DSH_PORT:-${PORT:-3080}}"
if command -v lsof >/dev/null 2>&1; then
    PIDS="$(lsof -ti ":${TARGET_PORT}" 2>/dev/null || true)"
    if [ -n "$PIDS" ]; then
        echo "$PIDS" | xargs kill -15 2>/dev/null || true
        sleep 0.5
        STILL_ALIVE="$(lsof -ti ":${TARGET_PORT}" 2>/dev/null || true)"
        if [ -n "$STILL_ALIVE" ]; then
            echo "$STILL_ALIVE" | xargs kill -9 2>/dev/null || true
        fi
    fi
fi
if [ -f "${REAL_TARGET}/dsh.pid" ]; then
    PID="$(cat "${REAL_TARGET}/dsh.pid" 2>/dev/null || true)"
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
        kill -15 "$PID" 2>/dev/null || true
        sleep 0.2
        kill -9 "$PID" 2>/dev/null || true
    fi
    rm -f "${REAL_TARGET}/dsh.pid"
fi
echo "✅ Active processes on port ${TARGET_PORT} terminated."

echo "🧹 [2/3] Removing configuration directory: ${REAL_TARGET}..."
rm -rf "${REAL_TARGET}"
echo "✅ Configuration purged."

if [ "$IS_LOCAL_MODE" = true ]; then
    echo "🗑️  [3/3] Cleaning local workspace artifacts (node_modules, caches, logs)..."
    rm -rf node_modules .dsh *.log
    echo "✅ Local workspace cleaned."
else
    echo "🗑️  [3/3] Target configuration reset complete."
fi

echo ""
echo "✨ Reset complete! Specified target has been wiped."
echo "➡️ To reinstall and reconfigure, run: ./setup-dsh.sh"
echo "=========================================================================="
