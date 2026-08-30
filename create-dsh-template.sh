#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-dsh-template}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -e "$TARGET" ]; then
    echo "Error: target already exists: $TARGET"
    echo "Choose a new directory name or remove the existing folder first."
    exit 1
fi

mkdir -p "$TARGET/bin" "$TARGET/.dsh/profiles"

cp "${SCRIPT_DIR}/package.json" "$TARGET/package.json"
cp "${SCRIPT_DIR}/bun.lock" "$TARGET/bun.lock"
cp "${SCRIPT_DIR}/setup-dsh.sh" "$TARGET/setup-dsh.sh"
cp "${SCRIPT_DIR}/reset.sh" "$TARGET/reset.sh"
cp "${SCRIPT_DIR}/doctor.js" "$TARGET/doctor.js"
cp "${SCRIPT_DIR}/sync-models.js" "$TARGET/sync-models.js"
cp "${SCRIPT_DIR}/bin/"*.js "$TARGET/bin/"

chmod +x "$TARGET/setup-dsh.sh" "$TARGET/reset.sh" "$TARGET/sync-models.js"

cat > "$TARGET/.gitignore" <<'EOF'
.env
.env.*
!.env.example
*.credentials.yaml
.credentials.yaml
.dsh/.credentials.yaml
.dsh/.env
.dsh/.env.*
node_modules/
package-lock.json
pnpm-lock.yaml
.dsh-target
*.log
EOF

# Empty placeholders make the template structure visible without storing secrets.
: > "$TARGET/.dsh/cordis.patch.yml"
: > "$TARGET/.dsh/settings.yaml"
: > "$TARGET/.dsh/profiles/.gitkeep"

echo "Created vanilla DSH template at: $TARGET"
echo "No credentials, node_modules, or .dsh-target were written."
echo "To create a project from it:"
echo "  cp -R $TARGET project-a"
echo "  cd project-a"
echo "  ./setup-dsh.sh"
