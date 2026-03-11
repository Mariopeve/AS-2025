#!/usr/bin/env bash
set -euo pipefail

log() { printf '%s\n' "$*" >&2; }
die() { log "ERROR: $*"; exit 1; }

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo -E bash "$0" "$@"
  fi
  die "Este script necesita permisos de root (instala sudo o ejecútalo como root)."
fi

[[ -f /etc/os-release ]] || die "No se encontró /etc/os-release."
# shellcheck disable=SC1091
source /etc/os-release

DIST_ID="${ID:-}"
CODENAME="${VERSION_CODENAME:-}"

if [[ "$DIST_ID" != "ubuntu" && "$DIST_ID" != "debian" ]]; then
  die "Distribución no soportada: $DIST_ID (solo ubuntu/debian)."
fi

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y ca-certificates curl gnupg

if [[ -z "$CODENAME" ]]; then
  if ! command -v lsb_release >/dev/null 2>&1; then
    apt-get install -y lsb-release
  fi
  CODENAME="$(lsb_release -cs)"
fi

install -m 0755 -d /etc/apt/keyrings
if [[ ! -f /etc/apt/keyrings/docker.gpg ]]; then
  curl -fsSL "https://download.docker.com/linux/${DIST_ID}/gpg" | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
fi

ARCH="$(dpkg --print-architecture)"
printf '%s\n' "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DIST_ID} ${CODENAME} stable" > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable --now docker

TARGET_USER="${SUDO_USER:-${USER:-}}"
if [[ -n "$TARGET_USER" && "$TARGET_USER" != "root" ]] && id "$TARGET_USER" >/dev/null 2>&1; then
  groupadd -f docker
  usermod -aG docker "$TARGET_USER" || true
fi

docker --version
docker compose version

log "Listo. Si agregaste tu usuario al grupo 'docker', vuelve a iniciar sesión."