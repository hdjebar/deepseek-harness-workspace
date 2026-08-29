#!/usr/bin/env bash
set -euo pipefail

FORCE=false
if [[ "${1:-}" == "-y" || "${1:-}" == "--force" || "${1:-}" == "-f" ]]; then
    FORCE=true
fi

echo "=========================================================================="
echo "    DEEPSEEK HARNESS (DSH) COMPLETE RESET & CLEAN SLATE                   "
echo "=========================================================================="
echo ""
echo "⚠️  WARNING: This will perform the following actions:"
echo "   1. Terminate any active DSH background processes and servers on port 3080"
echo "   2. Wipe the global configuration & credential store (~/.dsh)"
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

echo "🧹 [2/3] Removing global ~/.dsh directory (credentials, profiles, patches)..."
rm -rf "$HOME/.dsh"
echo "✅ Global configuration purged."

echo "🗑️  [3/3] Cleaning local workspace artifacts (node_modules, caches, logs)..."
rm -rf node_modules .dsh *.log /tmp/dsh-*
echo "✅ Local workspace cleaned."

echo ""
echo "✨ Full reset complete! Your system is back to a clean slate."
echo "➡️ To reinstall and reconfigure, run: ./setup-dsh.sh"
echo "=========================================================================="
