#!/usr/bin/env bash
# Instala Cline CLI 3.0.46 en un prefijo propio y lo apunta a LocalAI.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$HERE/common.sh"

require_basics
normalize_localai
PREFIX="${CLINE_CLI_PREFIX:-$HOME/.local/share/cline-cli-localai}"
mkdir -p "$PREFIX/cline-home/data/settings"
tutorial_init "$PREFIX"
tutorial_step "URL de LocalAI" "LOCALAI_URL=${LOCALAI_ORIGIN}
API=${LOCALAI_API_BASE}"

ensure_node "$PREFIX"
tutorial_step "Node" "$(node --version)
$(command -v node)"

npm install -g --prefix "$PREFIX/.cli" cline@3.0.46
tutorial_step "Binario" "$("$PREFIX/.cli/bin/cline" --version)
$PREFIX/.cli/bin/cline"

read_models "$HERE/fetch_models.py" \
  --base "$LOCALAI_API_BASE" \
  --models-dir "${LOCALAI_MODELS_DIR:-}" \
  --active "${LOCALAI_MODEL:-}" \
  --api-key "${LOCALAI_API_KEY:-}" \
  --write cline \
  --out "$PREFIX/cline-home/data/settings/providers.json" \
  --list-file "$PREFIX/models.txt"
write_localai_env "$PREFIX"
cp "$HERE/common.sh" "$PREFIX/common.sh"
cp "$HERE/run-cline-cli.sh" "$PREFIX/run-cline-cli.sh"
chmod 755 "$PREFIX/run-cline-cli.sh"

tutorial_step "Modelos" "$(wc -l <"$PREFIX/models.txt") modelos. Activo: ${ACTIVE_MODEL}
$(cat "$PREFIX/models.txt")"
tutorial_step "Proveedor" "CLINE_DIR=${PREFIX}/cline-home
baseUrl=${LOCALAI_API_BASE}"
tutorial_step "Arranque" "${PREFIX}/run-cline-cli.sh <WORKSPACE>"
echo "Listo. Tutorial: ${PREFIX}/TUTORIAL.md"
