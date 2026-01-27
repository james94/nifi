#!/usr/bin/env bash
set -euo pipefail

# Read image from DockerImage.txt (e.g., apache/nifi-registry:2.6.0)
DOCKER_IMAGE="$(grep -Ev '(^#|^\s*$|^\s*\t*#)' "$(dirname "$0")/DockerImage.txt")"
REGISTRY_VERSION="$(echo "${DOCKER_IMAGE}" | cut -d : -f 2)"
CONTAINER_NAME="${CONTAINER_NAME:-nifi-registry}"

# Shared network so NiFi can resolve 'nifi-registry' by name
DOCKER_NETWORK="${DOCKER_NETWORK:-fleet-net}"
if ! docker network inspect "${DOCKER_NETWORK}" >/dev/null 2>&1; then
  echo "Creating network: ${DOCKER_NETWORK}"
  docker network create "${DOCKER_NETWORK}"
fi

# Host persistence dirs (override via env if desired)
ROOT="${ROOT:-/home/ubuntu/src/james/nifi/nifi-registry/data}"
HOST_FLOW_STORAGE_DIR="${HOST_FLOW_STORAGE_DIR:-${ROOT}/flow_storage}"
HOST_BUNDLE_STORAGE_DIR="${HOST_BUNDLE_STORAGE_DIR:-${ROOT}/extension_bundles}"
HOST_DB_DIR="${HOST_DB_DIR:-${ROOT}/database}"

mkdir -p "${HOST_FLOW_STORAGE_DIR}" "${HOST_BUNDLE_STORAGE_DIR}" "${HOST_DB_DIR}"

# Ports and AUTH
AUTH="${AUTH:-}"
REGISTRY_HTTP_PORT="${REGISTRY_HTTP_PORT:-18080}"
REGISTRY_HTTPS_PORT="${REGISTRY_HTTPS_PORT:-18443}"

# Resolve single host IP (first column of 'hostname -I') for UI hints
REGISTRY_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
if [ -z "${REGISTRY_IP}" ]; then
  REGISTRY_IP="$(hostname -i 2>/dev/null | awk '{print $1}')"
fi

# Args
PORT_ARGS=()
ENV_ARGS=()
VOLUME_ARGS=(
  -v "${HOST_FLOW_STORAGE_DIR}:/opt/nifi-registry/nifi-registry-current/flow_storage:rw"
  -v "${HOST_BUNDLE_STORAGE_DIR}:/opt/nifi-registry/nifi-registry-current/extension_bundles:rw"
  -v "${HOST_DB_DIR}:/opt/nifi-registry/nifi-registry-current/database:rw"
)

if [ -z "${AUTH}" ]; then
  PORT_ARGS+=(-p "${REGISTRY_HTTP_PORT}:18080")
  ENV_ARGS+=(-e NIFI_REGISTRY_WEB_HTTP_PORT="${REGISTRY_HTTP_PORT}")
else
  PORT_ARGS+=(-p "${REGISTRY_HTTPS_PORT}:18443")
  ENV_ARGS+=(-e AUTH="${AUTH}" -e NIFI_REGISTRY_WEB_HTTPS_PORT="${REGISTRY_HTTPS_PORT}")
fi
# Advertise by container name on Docker network (alternative to container ID)
ENV_ARGS+=(-e NIFI_REGISTRY_HOST="${CONTAINER_NAME}")

echo "Running NiFi Registry:"
echo "  Image:    ${DOCKER_IMAGE}"
echo "  Name:     ${CONTAINER_NAME}"
echo "  Network:  ${DOCKER_NETWORK}"
echo "  Volumes:"
echo "    flow_storage       -> ${HOST_FLOW_STORAGE_DIR}"
echo "    extension_bundles  -> ${HOST_BUNDLE_STORAGE_DIR}"
echo "    database(H2)       -> ${HOST_DB_DIR}"
echo "  Ports:"
if [ -z "${AUTH}" ]; then
  echo "    HTTP:  ${REGISTRY_HTTP_PORT}"
else
  echo "    HTTPS: ${REGISTRY_HTTPS_PORT}"
fi

# Remove existing container if present
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container ${CONTAINER_NAME} exists; removing..."
  docker rm -f "${CONTAINER_NAME}" >/dev/null
fi

# Run
docker run -d --name "${CONTAINER_NAME}" \
  --network "${DOCKER_NETWORK}" \
  "${PORT_ARGS[@]}" \
  "${VOLUME_ARGS[@]}" \
  "${ENV_ARGS[@]}" \
  "${DOCKER_IMAGE}"

# Hints: connect by container name (preferred) or host IP
if [ -z "${AUTH}" ]; then
  echo "NiFi Registry UI: http://${CONTAINER_NAME}:${REGISTRY_HTTP_PORT}/nifi-registry"
  [ -n "${REGISTRY_IP}" ] && echo "Alt:               http://${REGISTRY_IP}:${REGISTRY_HTTP_PORT}/nifi-registry"
  echo "In NiFi UI -> Registries -> Add:"
  echo "  URL: http://${CONTAINER_NAME}:${REGISTRY_HTTP_PORT}/nifi-registry"
else
  echo "NiFi Registry UI: https://${CONTAINER_NAME}:${REGISTRY_HTTPS_PORT}/nifi-registry"
  [ -n "${REGISTRY_IP}" ] && echo "Alt:               https://${REGISTRY_IP}:${REGISTRY_HTTPS_PORT}/nifi-registry"
  echo "In NiFi UI -> Registries -> Add:"
  echo "  URL: https://${CONTAINER_NAME}:${REGISTRY_HTTPS_PORT}/nifi-registry"
fi
