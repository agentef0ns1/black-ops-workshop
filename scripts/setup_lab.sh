#!/bin/bash
# Reinicia el laboratorio: pregunta qué grupos levantar, asegura la ipvlan L2
# y arranca solo esos perfiles.
# L2 mantiene una IP propia en la LAN sin pedir el modo promiscuo de macvlan.
# El rango 192.168.1.128/26 cubre .129-.190. Los servicios clásicos usan .145-.190.
# El perfil ai usa .141, .142 y .143.
set -euo pipefail

IFACE="${IFACE:-wlo1}"
SUBNET="${SUBNET:-192.168.1.0/24}"
IP_RANGE="${IP_RANGE:-192.168.1.128/26}"
GATEWAY="${GATEWAY:-192.168.1.1}"
NET_NAME="${NET_NAME:-lan_ipvlan}"
IPVLAN_MODE="${IPVLAN_MODE:-l2}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
COMPOSE=(docker compose -f "$ROOT/docker-compose.yml")
INVENTORY="$ROOT/inventory.txt"

NORMAL=(core mail legacy printer java messaging registry monitoring data storage net windows)
HEAVY=(directory elastic data-heavy hadoop docker ai)
ALL_PROFILES=("${NORMAL[@]}" "${HEAVY[@]}")

declare -A SELECTED=()

usage() {
  echo "Uso: $0 [--yes | --all | --only grupo,grupo]" >&2
  echo "Sin argumentos y con terminal, pregunta. Sin terminal equivale a --yes." >&2
  echo "Grupos: ${ALL_PROFILES[*]}" >&2
}

clear_selected() {
  local name
  for name in "${ALL_PROFILES[@]}"; do
    unset "SELECTED[$name]"
  done
}

mark_normal() {
  clear_selected
  local name
  for name in "${NORMAL[@]}"; do
    SELECTED["$name"]=1
  done
}

mark_all() {
  clear_selected
  local name
  for name in "${ALL_PROFILES[@]}"; do
    SELECTED["$name"]=1
  done
}

mark_only() {
  clear_selected
  local item name known
  IFS=',' read -r -a items <<< "$1"
  for item in "${items[@]}"; do
    known=0
    for name in "${ALL_PROFILES[@]}"; do
      if [ "$item" = "$name" ]; then
        known=1
        SELECTED["$name"]=1
      fi
    done
    if [ "$known" -ne 1 ]; then
      echo "Grupo desconocido: $item" >&2
      usage
      exit 1
    fi
  done
}

choose_groups() {
  local choice index name heavy mark
  while true; do
    echo "Laboratorios. Enter acepta. Un número alterna. a = todos menos pesados. t = todos. q = salir."
    index=1
    for name in "${ALL_PROFILES[@]}"; do
      if [ -n "${SELECTED[$name]:-}" ]; then
        mark="[x]"
      else
        mark="[ ]"
      fi
      heavy=""
      for item in "${HEAVY[@]}"; do
        if [ "$item" = "$name" ]; then
          heavy=" pesado"
        fi
      done
      printf ' %2d %s %s%s\n' "$index" "$mark" "$name" "$heavy"
      index=$((index + 1))
    done
    if ! read -r choice; then
      choice=""
    fi
    case "$choice" in
      "")
        return 0
        ;;
      a|A)
        mark_normal
        ;;
      t|T)
        mark_all
        ;;
      q|Q)
        echo "No se cambia el laboratorio."
        exit 0
        ;;
      *)
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#ALL_PROFILES[@]}" ]; then
          name="${ALL_PROFILES[$((choice - 1))]}"
          if [ -n "${SELECTED[$name]:-}" ]; then
            unset 'SELECTED[$name]'
          else
            SELECTED["$name"]=1
          fi
        else
          echo "Opción no válida: $choice" >&2
        fi
        ;;
    esac
  done
}

MODE="ask"
ONLY=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --yes) MODE="yes" ;;
    --all) MODE="all" ;;
    --only)
      shift
      ONLY="${1:-}"
      MODE="only"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Argumento no válido: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
done

case "$MODE" in
  yes) mark_normal ;;
  all) mark_all ;;
  only) mark_only "$ONLY" ;;
  ask)
    mark_normal
    if [ -t 0 ] && [ -t 1 ]; then
      choose_groups
    fi
    ;;
esac

if [ "${#SELECTED[@]}" -eq 0 ]; then
  echo "No hay ningún grupo seleccionado." >&2
  exit 1
fi

if ! ip link show "$IFACE" >/dev/null 2>&1; then
  echo "La interfaz ${IFACE} no existe. Exporta IFACE con el nombre real." >&2
  exit 1
fi

create_network() {
  docker network create -d ipvlan \
    --subnet="$SUBNET" \
    --ip-range="$IP_RANGE" \
    --gateway="$GATEWAY" \
    -o parent="$IFACE" \
    -o ipvlan_mode="$IPVLAN_MODE" \
    "$NET_NAME"
}

down_args=()
for name in "${ALL_PROFILES[@]}"; do
  down_args+=(--profile "$name")
done

echo "Parando el laboratorio..."
"${COMPOSE[@]}" "${down_args[@]}" down --remove-orphans

if docker network inspect "$NET_NAME" >/dev/null 2>&1; then
  current="$(docker network inspect -f '{{(index .IPAM.Config 0).IPRange}}' "$NET_NAME" 2>/dev/null || true)"
  parent="$(docker network inspect -f '{{index .Options "parent"}}' "$NET_NAME" 2>/dev/null || true)"
  mode="$(docker network inspect -f '{{index .Options "ipvlan_mode"}}' "$NET_NAME" 2>/dev/null || true)"
  if [ "$current" != "$IP_RANGE" ] || [ "$parent" != "$IFACE" ] || [ "$mode" != "$IPVLAN_MODE" ]; then
    echo "Recreando ${NET_NAME}: rango=${current:-?} parent=${parent:-?} modo=${mode:-?}."
    docker network rm "$NET_NAME"
    create_network
  fi
else
  create_network
fi

load_mod() {
  modprobe "$1" 2>/dev/null || sudo -n modprobe "$1"
}
if [ -n "${SELECTED[core]:-}" ] || [ -n "${SELECTED[storage]:-}" ]; then
  for mod in nfs nfsd; do
    if ! lsmod | awk '{print $1}' | grep -qx "$mod"; then
      load_mod "$mod" || echo "No se pudo cargar ${mod}. En el host: sudo modprobe ${mod}" >&2
    fi
  done
fi
if [ -n "${SELECTED[elastic]:-}" ]; then
  echo "Elasticsearch necesita vm.max_map_count >= 262144. En el host: sudo sysctl -w vm.max_map_count=262144"
fi

up_args=()
for name in "${ALL_PROFILES[@]}"; do
  if [ -n "${SELECTED[$name]:-}" ]; then
    up_args+=(--profile "$name")
  fi
done

echo "Levantando: ${up_args[*]}"
"${COMPOSE[@]}" "${up_args[@]}" up -d --build
"${COMPOSE[@]}" "${up_args[@]}" ps -a

echo "Laboratorio en lan_ipvlan (ipvlan L2)"
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  [[ -z "$line" ]] && continue
  profile="${line%% *}"
  if [ -n "${SELECTED[$profile]:-}" ]; then
    echo "  ${line#* }"
  fi
done < "$INVENTORY"
echo
echo "El banner SMTP de .153 debe contener ESMTP Postfix."
echo "SNMP, NTP y TFTP son UDP: el descubrimiento TCP no los ve si nmap no lleva -sU."
