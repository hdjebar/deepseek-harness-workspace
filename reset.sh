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
            if [[ -n "${2:-}" ]]; then
                CUSTOM_DIR="$2"
                shift 2
            else
                shift
            fi
            ;;
        --force|-f|-y)
            FORCE=true
            shift
            ;;
        *)
            shift
            ;;
    esac
done

if [[ -n "$CUSTOM_DIR" ]]; then
    TARGET_DSH="$CUSTOM_DIR"
elif [ "$GLOBAL_RESET" = true ]; then
    TARGET_DSH="$HOME/.dsh"
else
    if [ -d "$(pwd)/.dsh" ]; then
        TARGET_DSH="$(pwd)/.dsh"
    else
        TARGET_DSH="$HOME/.dsh"
    fi
fi

echo "=========================================================================="
echo "    DEEPSEEK HARNESS (DSH) COMPLETE RESET & CLEAN SLATE                   "
echo "=========================================================================="
echo ""
echo "⚠️  WARNING: This will perform the following actions:"
echo "   1. Terminate any active DSH background processes and servers on port 3080"
echo "   2. Wipe the target configuration & credential store (${TARGET_DSH})"
echo "   3. Purge local node_modules, caches, and runtime logs"
echo ""

if [ "$FORCE" = false ]; then
    read -rp "Are you sure you want to completely reset? [y/N]: " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
        echo "❌ Reset cancelled."
        exit 0
    fi
fi

echo ""
echo "🛑 [1/3] Terminating active DSH background processes..."
lsof -ti :3080 2>/dev/null | xargs kill -9 2>/dev/null || true
pkill -9 -f "bun.*dsh" 2>/dev/null || true
pkill -9 -f "dsh-tui" 2>/dev/null || true
echo "✅ Processes terminated."

echo "🧹 [2/3] Removing configuration directory: ${TARGET_DSH}..."
rm -rf "${TARGET_DSH}"
echo "✅ Configuration purged."

echo "🗑️  [3/3] Cleaning local workspace artifacts (node_modules, caches, logs)..."
rm -rf node_modules .dsh *.log /tmp/dsh-*
echo "✅ Local workspace cleaned."

echo ""
echo "✨ Full reset complete! Your system is back to a clean slate."
echo "➡️ To reinstall and reconfigure, run: ./setup-dsh.sh"
echo "=========================================================================="
