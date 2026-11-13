#!/usr/bin/env bash
# Configura la extensión Cline contra LocalAI. No instala el editor.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$HERE/common.sh"

require_basics
normalize_localai
PREFIX="${CLINE_DATA:-$HOME/.cline}"
mkdir -p "$PREFIX/data/settings"
tutorial_init "$PREFIX"
tutorial_step "URL de LocalAI" "LOCALAI_URL=${LOCALAI_ORIGIN}
API=${LOCALAI_API_BASE}
Upstream=${UPSTREAM_HOST}:${UPSTREAM_PORT}"

read_models "$HERE/fetch_models.py" \
  --base "$LOCALAI_API_BASE" \
  --models-dir "${LOCALAI_MODELS_DIR:-}" \
  --active "${LOCALAI_MODEL:-}" \
  --api-key "${LOCALAI_API_KEY:-}" \
  --write cline \
  --out "$PREFIX/data/settings/providers.json" \
  --list-file "$PREFIX/models.txt"
write_localai_env "$PREFIX"
cp "$HERE/common.sh" "$PREFIX/common.sh"
cp "$HERE/run-cline.sh" "$PREFIX/run-cline.sh"
chmod 755 "$PREFIX/run-cline.sh"

tutorial_step "Modelos" "$(wc -l <"$PREFIX/models.txt") modelos. Activo: ${ACTIVE_MODEL}
$(cat "$PREFIX/models.txt")"
tutorial_step "Proveedor" "Fichero: ${PREFIX}/data/settings/providers.json
lastUsedProvider=openai-compatible
baseUrl=${LOCALAI_API_BASE}"
tutorial_step "Extensión" "Instala la extensión Cline en el editor y recárgalo.
El selector lee los modelos en ${LOCALAI_API_BASE}/models."
tutorial_step "Arranque" "${PREFIX}/run-cline.sh <WORKSPACE>"
echo "Listo. Tutorial: ${PREFIX}/TUTORIAL.md"
