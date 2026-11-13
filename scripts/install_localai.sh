#!/usr/bin/env bash
# Instalador completo de LocalAI + llama.cpp CUDA 12 + Qwen3.8-4B GGUF
# Diseñado para Ubuntu x86_64 con Docker/Compose ya instalados y NVIDIA.
# Genera su propio compose.yaml: NO necesita archivos de una instalación anterior.
# No desinstala Docker, no toca el driver NVIDIA y no borra otros contenedores.

set -Eeuo pipefail
IFS=$'\n\t'

# ----------------------------- Configuración -----------------------------
LOCALAI_DIR="${LOCALAI_DIR:-$HOME/localai}"
LOCALAI_IMAGE="${LOCALAI_IMAGE:-localai/localai:latest-gpu-nvidia-cuda-12}"
LOCALAI_BIND_ADDRESS="${LOCALAI_BIND_ADDRESS:-127.0.0.1}"
LOCALAI_PORT="${LOCALAI_PORT:-8080}"
MODEL_NAME="${MODEL_NAME:-qwen3.8-4b-tools}"
MODEL_CONTEXT="${MODEL_CONTEXT:-2048}"
MODEL_THREADS="${MODEL_THREADS:-4}"
MODEL_DIR_NAME="qwen3.8-4b"
MODEL_FILE_NAME="Qwen3.8-4B-Q4_K_M.gguf"
MODEL_URL="${MODEL_URL:-https://huggingface.co/Flowsink/Qwen3.8-4B-Distill-GGUF/resolve/main/${MODEL_FILE_NAME}}"
API_URL="http://127.0.0.1:${LOCALAI_PORT}"
# LocalAI drops privileges to LOCALAI_UID/GID. Match the host owner of bind mounts.
HOST_UID="$(id -u)"
HOST_GID="$(id -g)"

log()  { printf '\n\033[1;32m[LOCALAI-INSTALL]\033[0m %s\n' "$*"; }
warn() { printf '\n\033[1;33m[AVISO]\033[0m %s\n' "$*" >&2; }
die()  { printf '\n\033[1;31m[ERROR]\033[0m %s\n' "$*" >&2; exit 1; }

on_error() {
  local rc=$?
  printf '\n[ERROR] Falló la línea %s (código %s).\n' "${BASH_LINENO[0]:-?}" "$rc" >&2
  if command -v docker >/dev/null 2>&1 && [[ -f "${LOCALAI_DIR:-}/compose.yaml" ]]; then
    printf '\nÚltimos logs del contenedor LocalAI:\n' >&2
    docker compose -f "$LOCALAI_DIR/compose.yaml" logs --tail=100 local-ai >&2 || true
    sudo docker compose -f "$LOCALAI_DIR/compose.yaml" logs --tail=100 local-ai >&2 || true
  fi
  exit "$rc"
}
trap on_error ERR

# ----------------------------- Validaciones -------------------------------
[[ "$EUID" -ne 0 ]] || die "Ejecuta este script como usuario normal, sin sudo. Se pedirá sudo cuando haga falta."
[[ "$(uname -m)" == "x86_64" ]] || die "Este instalador está preparado para Linux x86_64."
command -v sudo >/dev/null 2>&1 || die "No encuentro sudo."
sudo -v

[[ "$LOCALAI_PORT" =~ ^[0-9]+$ ]] && (( LOCALAI_PORT >= 1 && LOCALAI_PORT <= 65535 )) || die "LOCALAI_PORT no es válido."
[[ "$MODEL_CONTEXT" =~ ^[0-9]+$ ]] && (( MODEL_CONTEXT >= 512 )) || die "MODEL_CONTEXT debe ser un entero >= 512."
[[ "$MODEL_THREADS" =~ ^[0-9]+$ ]] && (( MODEL_THREADS >= 1 )) || die "MODEL_THREADS debe ser un entero positivo."
[[ "$MODEL_NAME" =~ ^[a-zA-Z0-9._-]+$ ]] || die "MODEL_NAME contiene caracteres no permitidos."

command -v nvidia-smi >/dev/null 2>&1 || die "No encuentro nvidia-smi en el host. Instala/repara el driver NVIDIA antes de continuar."
nvidia-smi >/dev/null || die "El driver NVIDIA no responde correctamente."

# Instalar utilidades pequeñas si faltan.
missing=()
for bin in curl jq awk df find head; do
  command -v "$bin" >/dev/null 2>&1 || missing+=("$bin")
done
if ((${#missing[@]})); then
  log "Instalando dependencias del sistema..."
  sudo apt-get update
  sudo apt-get install -y curl jq coreutils findutils gawk
fi

command -v docker >/dev/null 2>&1 || die "Docker no está instalado. Instala Docker Engine antes de ejecutar este instalador."
docker compose version >/dev/null 2>&1 || die "Falta Docker Compose v2 (comando: docker compose). Instala docker-compose-plugin."

# Permite tanto Docker accesible por el usuario como instalaciones que requieren sudo.
DOCKER=(docker)
if ! docker info >/dev/null 2>&1; then
  if sudo docker info >/dev/null 2>&1; then
    DOCKER=(sudo docker)
    warn "Docker requiere sudo; las operaciones Docker se ejecutarán con sudo."
  else
    die "No puedo conectar con el daemon Docker, ni como usuario ni con sudo. Comprueba: sudo systemctl status docker"
  fi
fi
compose() { "${DOCKER[@]}" compose -f "$COMPOSE_FILE" "$@"; }

# The container may create backend files while running as root or as LocalAI's
# unprivileged uid. Normalize the bind mount for this host user before inspecting it.
normalize_backend_permissions() {
  [[ -d "$BACKENDS_DIR" ]] || return 0
  sudo chown -R "$HOST_UID:$HOST_GID" "$BACKENDS_DIR"
  sudo find "$BACKENDS_DIR" -type d -exec chmod u+rwx {} +
  sudo find "$BACKENDS_DIR" -type f -exec chmod u+rw {} +
  # Keep executable bits from the OCI artifact; ensure run.sh remains executable.
  sudo find "$BACKENDS_DIR" -type f -name 'run.sh' -exec chmod u+x {} +
}

wait_for_api() {
  local label="$1" ready=0
  log "$label"
  for _ in $(seq 1 180); do
    if curl -fsS "$API_URL/readyz" -o /dev/null 2>/dev/null; then
      ready=1
      break
    fi
    sleep 2
  done
  (( ready == 1 )) || die "LocalAI no llegó a readyz en 6 minutos. Revisa los logs del contenedor."
}

# ------------------------- Crear estructura limpia ------------------------
mkdir -p "$LOCALAI_DIR"
LOCALAI_DIR="$(cd "$LOCALAI_DIR" && pwd -P)"
MODELS_DIR="$LOCALAI_DIR/models"
BACKENDS_DIR="$LOCALAI_DIR/backends"
MODEL_SUBDIR="$MODELS_DIR/$MODEL_DIR_NAME"
MODEL_FILE="$MODEL_SUBDIR/$MODEL_FILE_NAME"
MODEL_CONFIG="$MODELS_DIR/${MODEL_NAME}.yaml"
COMPOSE_FILE="$LOCALAI_DIR/compose.yaml"

mkdir -p "$MODELS_DIR" "$BACKENDS_DIR" "$MODEL_SUBDIR"

# Si hay configuraciones previas en esta carpeta, se guardan copias antes de reemplazarlas.
if [[ -f "$COMPOSE_FILE" ]]; then
  cp -a "$COMPOSE_FILE" "$COMPOSE_FILE.bak.$(date +%Y%m%d-%H%M%S)"
fi
if [[ -f "$MODEL_CONFIG" ]]; then
  cp -a "$MODEL_CONFIG" "$MODEL_CONFIG.bak.$(date +%Y%m%d-%H%M%S)"
fi

# -------------------------- Descargar modelo Q4 ----------------------------
if [[ ! -f "$MODEL_FILE" ]] || (( $(stat -c %s "$MODEL_FILE" 2>/dev/null || echo 0) < 2500000000 )); then
  FREE_BYTES="$(df -PB1 "$MODELS_DIR" | awk 'NR==2 {print $4}')"
  (( FREE_BYTES > 3500000000 )) || die "Necesitas al menos 3,5 GB libres en $MODELS_DIR para descargar Qwen3.8-4B Q4_K_M."
  log "Descargando Qwen3.8-4B Q4_K_M (~2,78 GB). Si ya existe una descarga parcial, curl intentará reanudarla..."
  curl --fail --location --show-error --retry 5 --retry-all-errors --retry-delay 3 --continue-at - "$MODEL_URL" -o "$MODEL_FILE"
fi

MODEL_BYTES="$(stat -c %s "$MODEL_FILE")"
(( MODEL_BYTES > 2500000000 )) || die "El GGUF parece incompleto (solo ${MODEL_BYTES} bytes): $MODEL_FILE"
[[ "$(head -c 4 "$MODEL_FILE")" == "GGUF" ]] || die "El fichero descargado no tiene cabecera GGUF válida: $MODEL_FILE"
MODEL_RELATIVE="$MODEL_DIR_NAME/$MODEL_FILE_NAME"
MODEL_SIZE="$(du -h "$MODEL_FILE" | awk '{print $1}')"
log "Modelo local verificado: $MODEL_RELATIVE ($MODEL_SIZE)"

# ---------------------------- Crear Compose -------------------------------
# Tag CUDA 12. La detección NVIDIA se fuerza porque las GPU con 4 GiB
# pueden clasificarse como CPU por el autodetector.
cat > "$COMPOSE_FILE" <<YAML
services:
  local-ai:
    container_name: local-ai
    image: ${LOCALAI_IMAGE}
    pull_policy: always
    init: true
    ports:
      - "${LOCALAI_BIND_ADDRESS}:${LOCALAI_PORT}:8080"
    environment:
      DEBUG: "false"
      LOCALAI_MODELS_PATH: "/models"
      LOCALAI_BACKENDS_PATH: "/backends"
      LOCALAI_THREADS: "${MODEL_THREADS}"
      LOCALAI_FORCE_META_BACKEND_CAPABILITY: "nvidia"
      LOCALAI_UID: "${HOST_UID}"
      LOCALAI_GID: "${HOST_GID}"
      NVIDIA_DRIVER_CAPABILITIES: "compute,utility"
    volumes:
      - ./models:/models
      - ./backends:/backends
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: 1
              capabilities: [gpu]
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/readyz"]
      start_period: 10m
      interval: 30s
      timeout: 10s
      retries: 5
    restart: unless-stopped
YAML

# ------------------------- Configurar modelo YAML -------------------------
# gpu_layers se deja sin fijar para que llama.cpp ajuste las capas a la VRAM
# realmente libre. El resto del modelo permanece en RAM/CPU.
cat > "$MODEL_CONFIG" <<YAML
name: ${MODEL_NAME}
description: Qwen3.8-4B Q4_K_M - llama.cpp CUDA 12 - tool calling
backend: llama-cpp
parameters:
  model: "${MODEL_RELATIVE}"
  temperature: 0.6
  top_p: 0.95
  top_k: 20
  max_tokens: 2048
context_size: ${MODEL_CONTEXT}
threads: ${MODEL_THREADS}
low_vram: true
template:
  use_tokenizer_template: true
options:
  - use_jinja:true
function:
  disable_no_action: true
  automatic_tool_parsing_fallback: true
  grammar:
    disable: true
known_usecases:
  - chat
YAML
chmod 644 "$MODEL_CONFIG"
chmod 755 "$LOCALAI_DIR" "$MODELS_DIR" "$BACKENDS_DIR" "$MODEL_SUBDIR"

# ---------------------------- Arrancar LocalAI -----------------------------
log "Descargando la imagen LocalAI CUDA 12..."
compose pull

# Quita solo un contenedor anterior llamado local-ai, nunca otros contenedores.
"${DOCKER[@]}" rm -f local-ai >/dev/null 2>&1 || true
log "Creando el contenedor LocalAI..."
compose up -d

wait_for_api "Esperando a que la API esté lista..."

# La imagen oficial inicia como root y hace chown de /backends al UID/GID
# configurado. Normalizamos además cualquier archivo creado por docker exec.
normalize_backend_permissions

# ---------------------- Instalar backend CUDA llama.cpp -------------------
BACKEND_RUN="$(find "$BACKENDS_DIR" -mindepth 2 -maxdepth 4 -type f -name run.sh -path '*llama-cpp*' -print -quit 2>/dev/null || true)"
if [[ -z "$BACKEND_RUN" ]]; then
  log "Instalando backend llama-cpp. La capacidad NVIDIA selecciona la variante CUDA 12..."
  # En esta imagen el binario CLI reside en /local-ai, no en PATH.
  compose exec -T local-ai /local-ai backends install llama-cpp
  normalize_backend_permissions
  # Reiniciar para que LocalAI vuelva a descubrir el backend instalado.
  compose restart local-ai
  wait_for_api "Esperando a que LocalAI vuelva a estar listo tras instalar llama-cpp..."
  normalize_backend_permissions
  BACKEND_RUN="$(find "$BACKENDS_DIR" -mindepth 2 -maxdepth 4 -type f -name run.sh -path '*llama-cpp*' -print -quit 2>/dev/null || true)"
else
  log "Backend llama.cpp ya existe; se conserva: ${BACKEND_RUN#"$LOCALAI_DIR"/}"
fi

[[ -n "$BACKEND_RUN" && -x "$BACKEND_RUN" ]] || die "No se encuentra un run.sh ejecutable de llama.cpp bajo $BACKENDS_DIR. Ejecuta: docker exec local-ai /local-ai backends list"
BACKEND_CONTAINER_PATH="/backends/${BACKEND_RUN#"$BACKENDS_DIR"/}"
compose exec -T local-ai test -x "$BACKEND_CONTAINER_PATH" || die "El backend existe en el host, pero el contenedor no puede ejecutarlo: $BACKEND_CONTAINER_PATH"

# ------------------------ Crear servicio systemd --------------------------
DOCKER_BIN="$(command -v docker)"
RUN_USER="$(id -un)"
RUN_GROUP="$(id -gn)"
RUN_HOME="$HOME"
if [[ "${DOCKER[0]}" == "sudo" ]]; then
  UNIT_USER="root"
  UNIT_HOME="/root"
else
  UNIT_USER="$RUN_USER"
  UNIT_HOME="$RUN_HOME"
fi
UNIT_TMP="$(mktemp)"
cat > "$UNIT_TMP" <<UNIT
[Unit]
Description=LocalAI (Docker Compose)
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
User=${UNIT_USER}
WorkingDirectory=${LOCALAI_DIR}
Environment=HOME=${UNIT_HOME}
ExecStart=${DOCKER_BIN} compose -f ${COMPOSE_FILE} up -d
ExecStop=${DOCKER_BIN} compose -f ${COMPOSE_FILE} stop
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
UNIT
sudo install -m 0644 "$UNIT_TMP" /etc/systemd/system/localai.service
rm -f "$UNIT_TMP"
sudo systemctl daemon-reload
sudo systemctl enable localai.service >/dev/null

# -------------------------- Prueba de inferencia ---------------------------
log "Probando inferencia de texto con ${MODEL_NAME}. La primera carga puede tardar..."
CHAT_BODY="$(jq -n --arg model "$MODEL_NAME" '{model:$model,messages:[{role:"user",content:"Responde exactamente QWEN_OK"}],temperature:0.1,max_tokens:64}')"
CHAT_RESPONSE="$(curl -fsS --max-time 900 -H 'Content-Type: application/json' -d "$CHAT_BODY" "$API_URL/v1/chat/completions")" || die "La API está activa, pero la inferencia del modelo falló. Revisa los logs y la compatibilidad del backend con Qwen3.5/Qwen3.8."
CHAT_TEXT="$(jq -r '.choices[0].message.content // .choices[0].message.reasoning_content // empty' <<<"$CHAT_RESPONSE")"
[[ -n "$CHAT_TEXT" ]] || die "La API respondió, pero no devolvió texto. Respuesta: $CHAT_RESPONSE"
printf '\nRespuesta de prueba: %s\n' "$CHAT_TEXT"

# Prueba de tool calling. Se informa como aviso si el modelo no emite un tool_call,
# ya que la inferencia base puede funcionar aunque el formato de herramientas falle.
log "Probando tool calling OpenAI-compatible..."
TOOL_BODY="$(jq -n --arg model "$MODEL_NAME" '{model:$model,messages:[{role:"user",content:"Necesito consultar el tiempo en Madrid. Llama a get_weather con city igual a Madrid; no respondas directamente."}],tools:[{type:"function",function:{name:"get_weather",description:"Consulta el tiempo de una ciudad",parameters:{type:"object",properties:{city:{type:"string"}},required:["city"]}}}],tool_choice:"required",temperature:0.1,max_tokens:256}')"
if TOOL_RESPONSE="$(curl -fsS --max-time 900 -H 'Content-Type: application/json' -d "$TOOL_BODY" "$API_URL/v1/chat/completions" 2>/dev/null)"; then
  TOOL_NAME="$(jq -r '.choices[0].message.tool_calls[0].function.name // empty' <<<"$TOOL_RESPONSE")"
  if [[ "$TOOL_NAME" == "get_weather" ]]; then
    TOOL_ARGS="$(jq -c '.choices[0].message.tool_calls[0].function.arguments // "{}"' <<<"$TOOL_RESPONSE")"
    log "Tool calling OK: ${TOOL_NAME} ${TOOL_ARGS}"
  else
    warn "La inferencia funciona, pero LocalAI no ha devuelto un tool_call estructurado. Respuesta:"
    jq '.choices[0].message // .' <<<"$TOOL_RESPONSE" 2>/dev/null || printf '%s\n' "$TOOL_RESPONSE"
  fi
else
  warn "No se pudo completar la prueba HTTP de tool calling. La inferencia básica sí ha funcionado; revisa logs y compatibilidad del parser."
fi

# El servicio se habilita para arranque al inicio. Ya está en ejecución mediante Compose.
log "Instalación completada."
printf '\n%-22s %s\n' \
  'Directorio:' "$LOCALAI_DIR" \
  'Compose:' "$COMPOSE_FILE" \
  'Imagen:' "$LOCALAI_IMAGE" \
  'Backend:' "$BACKEND_RUN" \
  'Modelo API:' "$MODEL_NAME" \
  'GGUF:' "$MODEL_FILE ($MODEL_SIZE)" \
  'Interfaz:' "http://${LOCALAI_BIND_ADDRESS}:${LOCALAI_PORT}" \
  'API:' "${API_URL}/v1" \
  'Servicio:' 'sudo systemctl status localai'
printf '\nComandos útiles:\n'
printf '  Logs:      cd "%s" && docker compose logs -f local-ai\n' "$LOCALAI_DIR"
printf '  Reiniciar: sudo systemctl restart localai\n'
printf '  Modelos:   curl -s %s/v1/models | jq\n' "$API_URL"