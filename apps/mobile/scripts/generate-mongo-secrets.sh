#!/bin/bash
set -euo pipefail

SRC_ROOT="${SRCROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
ENV_FILE="$SRC_ROOT/.env"
OUT_DIR="$SRC_ROOT/TrainingRecordApp/Generated"
OUT_FILE="$OUT_DIR/MONGODB_SECRETS.swift"

mkdir -p "$OUT_DIR"

URI=""
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" =~ ^MONGODB_URI= ]]; then
      URI="${line#MONGODB_URI=}"
      URI="${URI#"${URI%%[![:space:]]*}"}"
      URI="${URI%"${URI##*[![:space:]]}"}"
    fi
  done < "$ENV_FILE"
fi

# Escape for Swift string literal
ESC=$(printf '%s' "$URI" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g')

cat > "$OUT_FILE" <<EOF
// GENERATED — do not edit or commit. Created from apps/mobile/.env by generate-mongo-secrets.sh
enum MONGODB_SECRETS {
    static let URI = "$ESC"
}
EOF

echo "Wrote $OUT_FILE (uri configured: $([ -n "$URI" ] && echo yes || echo no))"
