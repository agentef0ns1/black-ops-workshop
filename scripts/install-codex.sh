#!/usr/bin/env bash
# Instala Codex 0.164.0, el catálogo de LocalAI y el proxy de tools.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
# shellcheck disable=SC1091
source "$HERE/common.sh"

require_basics
normalize_localai
PREFIX="${CODEX_PREFIX:-$HOME/.local/share/codex-localai}"
mkdir -p "$PREFIX/codex-proxy"
tutorial_init "$PREFIX"
tutorial_step "URL de LocalAI" "LOCALAI_URL=${LOCALAI_ORIGIN}
API=${LOCALAI_API_BASE}
El proveedor de Codex apunta a http://127.0.0.1:8082/v1
El proxy reenvía a ${UPSTREAM_HOST}:${UPSTREAM_PORT}"

ensure_node "$PREFIX"
tutorial_step "Node" "$(node --version)
$(command -v node)"

npm install -g --prefix "$PREFIX/.cli" @openai/codex@0.164.0
tutorial_step "Binario" "$("$PREFIX/.cli/bin/codex" --version)
$PREFIX/.cli/bin/codex"

read_models "$HERE/fetch_models.py" \
  --base "$LOCALAI_API_BASE" \
  --models-dir "${LOCALAI_MODELS_DIR:-}" \
  --active "${LOCALAI_MODEL:-}" \
  --api-key "${LOCALAI_API_KEY:-}" \
  --write codex \
  --out "$PREFIX" \
  --proxy-base "http://127.0.0.1:8082/v1" \
  --list-file "$PREFIX/models.txt"
write_localai_env "$PREFIX"
cp "$HERE/codex-proxy/proxy.py" "$HERE/codex-proxy/test_rewrite.py" "$PREFIX/codex-proxy/"
cp "$HERE/common.sh" "$PREFIX/common.sh"
cp "$HERE/run-codex.sh" "$PREFIX/run-codex.sh"
chmod 755 "$PREFIX/run-codex.sh"

(
  cd "$PREFIX/codex-proxy"
  python3 test_rewrite.py
)
tutorial_step "Proxy" "python3 ${PREFIX}/codex-proxy/test_rewrite.py
UPSTREAM_HOST=${UPSTREAM_HOST} UPSTREAM_PORT=${UPSTREAM_PORT} python3 ${PREFIX}/codex-proxy/proxy.py
Codex usa http://127.0.0.1:8082/v1. El proxy reenvía a ${UPSTREAM_HOST}:${UPSTREAM_PORT}.
Si 127.0.0.1:8082 ya estaba ocupado, este arranque no sustituye ese proceso. Páralo y vuelve a lanzar run-codex.sh para que coja este upstream."

start_codex_proxy "$PREFIX"
curl_models "http://127.0.0.1:8082/v1" >/dev/null
CODEX_HOME="$PREFIX" "$PREFIX/.cli/bin/codex" debug models >"$PREFIX/debug-models.json" 2>"$PREFIX/debug-models.err" \
  || {
    cat "$PREFIX/debug-models.err" >&2
    die "codex debug models falló"
  }
python3 - "$PREFIX/debug-models.json" "$ACTIVE_MODEL" <<'PY'
import json
import sys

data = json.loads(open(sys.argv[1], encoding="utf-8").read())
slugs = [item.get("slug") for item in data.get("models", [])]
need = sys.argv[2]
if need not in slugs:
    raise SystemExit(f"el catálogo de Codex no contiene {need}; primeros: {slugs[:5]}")
if slugs and all(str(slug).startswith("gpt-") for slug in slugs):
    raise SystemExit("Codex sigue con el catálogo de OpenAI")
print(f"codex debug models: {len(slugs)} slugs, activo {need}")
PY

tutorial_step "Modelos" "$(wc -l <"$PREFIX/models.txt") modelos. Activo: ${ACTIVE_MODEL}
model_catalog_json=${PREFIX}/localai-models.json
$(cat "$PREFIX/models.txt")"
tutorial_step "Arranque" "CODEX_HOME=${PREFIX} ${PREFIX}/run-codex.sh <WORKSPACE>"
echo "Listo. Tutorial: ${PREFIX}/TUTORIAL.md"
