#!/usr/bin/env bash

set -euo pipefail

PROJECT_ROOT="${1:-$(pwd)}"

if [[ ! -d "$PROJECT_ROOT" ]]; then
    echo "Project directory does not exist:"
    echo "$PROJECT_ROOT"
    exit 1
fi

PROJECT_ROOT="$(cd "$PROJECT_ROOT" && pwd)"

echo "========================================"
echo "Preparing project for GitHub"
echo "Root: $PROJECT_ROOT"
echo "========================================"
echo

cd "$PROJECT_ROOT"

echo "1. Removing empty files..."

while IFS= read -r -d '' file; do
    echo "Deleting empty file: ${file#"$PROJECT_ROOT"/}"
    rm -f -- "$file"
done < <(
    find "$PROJECT_ROOT" \
        -path "$PROJECT_ROOT/.git" -prune -o \
        -type f \
        -size 0 \
        -print0
)

echo
echo "2. Removing generated and temporary directories..."

TEMP_DIRS=(
    "node_modules"
    "dist"
    "build"
    ".cache"
    ".vite"
    ".parcel-cache"
    "coverage"
    ".nyc_output"
    "__pycache__"
    ".pytest_cache"
    ".mypy_cache"
    ".idea"
    ".vscode"
)

for dir_name in "${TEMP_DIRS[@]}"; do
    while IFS= read -r -d '' dir; do
        echo "Deleting directory: ${dir#"$PROJECT_ROOT"/}"
        rm -rf -- "$dir"
    done < <(
        find "$PROJECT_ROOT" \
            -path "$PROJECT_ROOT/.git" -prune -o \
            -type d \
            -name "$dir_name" \
            -print0
    )
done

echo
echo "3. Removing temporary files and archives..."

TEMP_FILE_PATTERNS=(
    "*.zip"
    "*.tar"
    "*.tar.gz"
    "*.tgz"
    "*.7z"
    "*.rar"
    "*.log"
    "*.tmp"
    "*.temp"
    "*.swp"
    "*.swo"
    "*~"
    ".DS_Store"
    "Thumbs.db"
    "npm-debug.log*"
    "yarn-debug.log*"
    "yarn-error.log*"
    "pnpm-debug.log*"
)

for pattern in "${TEMP_FILE_PATTERNS[@]}"; do
    while IFS= read -r -d '' file; do
        echo "Deleting file: ${file#"$PROJECT_ROOT"/}"
        rm -f -- "$file"
    done < <(
        find "$PROJECT_ROOT" \
            -path "$PROJECT_ROOT/.git" -prune -o \
            -type f \
            -name "$pattern" \
            -print0
    )
done

echo
echo "4. Removing empty directories..."

while IFS= read -r -d '' dir; do
    if [[ "$dir" != "$PROJECT_ROOT" ]]; then
        echo "Deleting empty directory: ${dir#"$PROJECT_ROOT"/}"
        rmdir -- "$dir" 2>/dev/null || true
    fi
done < <(
    find "$PROJECT_ROOT" \
        -depth \
        -type d \
        -empty \
        ! -path "$PROJECT_ROOT/.git" \
        ! -path "$PROJECT_ROOT/.git/*" \
        -print0
)

echo
echo "5. Creating .gitignore..."

cat > "$PROJECT_ROOT/.gitignore" <<'GITIGNORE'
# Dependencies
node_modules/

# Build output
dist/
build/
coverage/

# Tool caches
.cache/
.vite/
.parcel-cache/
.nyc_output/
.pytest_cache/
.mypy_cache/
__pycache__/

# Environment files and secrets
.env
.env.*
!.env.example
*.pem
*.key
*.crt
*.p12
*.pfx

# Fleet Manager runtime state
deploy/state/
deploy/state-backup*/
backups/

# Logs
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*
pnpm-debug.log*

# Archives
*.zip
*.tar
*.tar.gz
*.tgz
*.7z
*.rar

# Temporary editor files
*.tmp
*.temp
*.swp
*.swo
*~
.DS_Store
Thumbs.db

# IDE settings
.idea/
.vscode/

# Local validation/customization files
preslav-customization.json
customization.local.json
GITIGNORE

echo
echo "6. Checking required template files..."

REQUIRED_PATHS=(
    "contracts"
    "templates/preslav-bms/index.vue"
    "templates/preslav-bms/manifest.ts"
)

FAILED=0

for path in "${REQUIRED_PATHS[@]}"; do
    if [[ -e "$PROJECT_ROOT/$path" ]]; then
        echo "OK      $path"
    else
        echo "MISSING $path"
        FAILED=1
    fi
done

echo
echo "7. Checking for direct backend calls..."

if grep -RniE \
    "fetch[[:space:]]*\(|axios|/rpc|/api/" \
    "$PROJECT_ROOT/templates/preslav-bms" \
    --include="*.vue" \
    --include="*.ts" \
    --include="*.js"
then
    echo
    echo "WARNING: Possible direct backend calls were found."
else
    echo "No obvious direct backend calls found."
fi

echo
echo "8. Checking Host SDK imports..."

grep -Rni "@host" \
    "$PROJECT_ROOT/templates/preslav-bms" \
    --include="*.vue" \
    --include="*.ts" \
    || true

echo
echo "9. Final project files..."

find "$PROJECT_ROOT" \
    -path "$PROJECT_ROOT/.git" -prune -o \
    -type f \
    -print \
    | sed "s#^$PROJECT_ROOT/##" \
    | sort

echo
echo "========================================"

if [[ "$FAILED" -eq 1 ]]; then
    echo "Cleanup finished, but required files are missing."
    exit 1
fi

echo "Project is ready for GitHub review."
echo "========================================"
