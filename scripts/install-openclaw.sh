#!/usr/bin/env bash
# Instala OpenClaw 2026.10.5 en un prefijo propio y escribe todos los modelos.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$HERE/common.sh"

require_basics
normalize_localai
PREFIX="${OPENCLAW_PREFIX:-$HOME/.local/share/openclaw-localai}"
mkdir -p "$PREFIX/.openclaw"
tutorial_init "$PREFIX"
tutorial_step "URL de LocalAI" "LOCALAI_URL=${LOCALAI_ORIGIN}
API=${LOCALAI_API_BASE}
OpenClaw habla con LocalAI directo. No usa el proxy de Codex."

ensure_node "$PREFIX"
tutorial_step "Node" "$(node --version)
$(command -v node)"

npm install -g --prefix "$PREFIX/.cli" openclaw@2026.10.5
tutorial_step "Binario" "$("$PREFIX/.cli/bin/openclaw" --version)
$PREFIX/.cli/bin/openclaw"

read_models "$HERE/fetch_models.py" \
  --base "$LOCALAI_API_BASE" \
  --models-dir "${LOCALAI_MODELS_DIR:-}" \
  --active "${LOCALAI_MODEL:-}" \
  --api-key "${LOCALAI_API_KEY:-}" \
  --write openclaw \
  --out "$PREFIX/.openclaw/openclaw.json" \
  --list-file "$PREFIX/models.txt"
write_localai_env "$PREFIX"
cp "$HERE/common.sh" "$PREFIX/common.sh"
cp "$HERE/run-openclaw.sh" "$PREFIX/run-openclaw.sh"
chmod 755 "$PREFIX/run-openclaw.sh"

tutorial_step "Modelos" "$(wc -l <"$PREFIX/models.txt") modelos. Activo: localai/${ACTIVE_MODEL}
baseUrl=${LOCALAI_API_BASE}
$(cat "$PREFIX/models.txt")"
tutorial_step "Arranque" "${PREFIX}/run-openclaw.sh <WORKSPACE>"
echo "Listo. Tutorial: ${PREFIX}/TUTORIAL.md"
