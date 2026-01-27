#!/usr/bin/env bash

# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

DOCKER_IMAGE="$(grep -Ev '(^#|^\s*$|^\s*\t*#)' DockerImage.txt)"
NIFI_IMAGE_VERSION="$(echo "${DOCKER_IMAGE}" | cut -d : -f 2)"
# CONTAINER_NAME="${CONTAINER_NAME:-nifi-${NIFI_IMAGE_VERSION}}"
CONTAINER_NAME="${CONTAINER_NAME:-nifi}"

# Ensure shared network exists
DOCKER_NETWORK="${DOCKER_NETWORK:-fleet-net}"
if ! docker network inspect "${DOCKER_NETWORK}" >/dev/null 2>&1; then
  echo "Creating network: ${DOCKER_NETWORK}"
  docker network create "${DOCKER_NETWORK}"
fi

# Host persistence root (override via env)
ROOT="${ROOT:-/home/ubuntu/src/james/nifi/nifi-docker/data}"
# CONF_DIR="${CONF_DIR:-${ROOT}/conf}"
LOG_DIR="${LOG_DIR:-${ROOT}/logs}"
DB_DIR="${DB_DIR:-${ROOT}/database_repository}"
FLOWFILE_DIR="${FLOWFILE_DIR:-${ROOT}/flowfile_repository}"
CONTENT_DIR="${CONTENT_DIR:-${ROOT}/content_repository}"
PROVENANCE_DIR="${PROVENANCE_DIR:-${ROOT}/provenance_repository}"
STATE_DIR="${STATE_DIR:-${ROOT}/state}"

HOST_PY_EXT_DIR="${HOST_PY_EXT_DIR:-/home/ubuntu/src/james/nifi/nifi-extension-bundles/nifi-py4j-extension-bundle/nifi-python-test-extensions/src/main/resources/extensions}"

PY_EXT_DIR="${PY_EXT_DIR:-${HOST_PY_EXT_DIR}}"
NAR_EXT_DIR="${NAR_EXT_DIR:-${ROOT}/nar_extensions}"

# mkdir -p "${CONF_DIR}" "${LOG_DIR}" "${DB_DIR}" "${FLOWFILE_DIR}" "${CONTENT_DIR}" \
#          "${PROVENANCE_DIR}" "${STATE_DIR}" "${PY_EXT_DIR}" "${NAR_EXT_DIR}"

mkdir -p "${LOG_DIR}" "${DB_DIR}" "${FLOWFILE_DIR}" "${CONTENT_DIR}" \
         "${PROVENANCE_DIR}" "${STATE_DIR}" "${PY_EXT_DIR}" "${NAR_EXT_DIR}"

# Volumes
VOLUME_ARGS=(
  # -v "${CONF_DIR}:/opt/nifi/nifi-current/conf:rw"
  -v "${LOG_DIR}:/opt/nifi/nifi-current/logs:rw"
  -v "${DB_DIR}:/opt/nifi/nifi-current/database_repository:rw"
  -v "${FLOWFILE_DIR}:/opt/nifi/nifi-current/flowfile_repository:rw"
  -v "${CONTENT_DIR}:/opt/nifi/nifi-current/content_repository:rw"
  -v "${PROVENANCE_DIR}:/opt/nifi/nifi-current/provenance_repository:rw"
  -v "${STATE_DIR}:/opt/nifi/nifi-current/state:rw"
  -v "${PY_EXT_DIR}:/opt/nifi/nifi-current/python_extensions:rw"
  -v "${NAR_EXT_DIR}:/opt/nifi/nifi-current/nar_extensions:rw"
)

# Ports (conditional HTTP/HTTPS based on AUTH)
AUTH="${AUTH:-}"
HTTP_PORT="${NIFI_WEB_HTTP_PORT:-8080}"
HTTPS_PORT="${NIFI_WEB_HTTPS_PORT:-8443}"
S2S_PORT="${NIFI_REMOTE_INPUT_SOCKET_PORT:-10000}"
DEBUG_PORT="${DEBUG_PORT:-8000}"

# Resolve single host IP (first column of 'hostname -I')
# NIFI_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
# if [ -z "${NIFI_IP}" ]; then
#   NIFI_IP="$(hostname -i 2>/dev/null | awk '{print $1}')"
# fi

PORT_ARGS=()
ENV_ARGS=()

if [ -z "${AUTH}" ]; then
  PORT_ARGS+=(-p "${HTTP_PORT}:8080")
  ENV_ARGS+=(-e NIFI_WEB_HTTP_PORT="${HTTP_PORT}")
else
  PORT_ARGS+=(-p "${HTTPS_PORT}:8443")
  ENV_ARGS+=(-e AUTH="${AUTH}" -e NIFI_WEB_HTTPS_PORT="${HTTPS_PORT}")
fi
PORT_ARGS+=(-p "${S2S_PORT}:10000" -p "${DEBUG_PORT}:8000")

# Optional remote input host override for S2S advertisement
# Bind UI to container interfaces (start.sh default), advertise S2S using container name on Docker network
ENV_ARGS+=(-e NIFI_HOST="${CONTAINER_NAME}" -e NIFI_REMOTE_INPUT_SOCKET_PORT="${S2S_PORT}")

echo "Running NiFi:"
echo "  Image:    ${DOCKER_IMAGE}"
echo "  Name:     ${CONTAINER_NAME}"
echo "  Network:  ${DOCKER_NETWORK}"
echo "  Volumes:"
# printf "    conf                -> %s\n" "${CONF_DIR}"
printf "    logs                -> %s\n" "${LOG_DIR}"
printf "    database_repository -> %s\n" "${DB_DIR}"
printf "    flowfile_repository -> %s\n" "${FLOWFILE_DIR}"
printf "    content_repository  -> %s\n" "${CONTENT_DIR}"
printf "    provenance_repo     -> %s\n" "${PROVENANCE_DIR}"
printf "    state               -> %s\n" "${STATE_DIR}"
printf "    python_extensions   -> %s\n" "${PY_EXT_DIR}"
printf "    nar_extensions      -> %s\n" "${NAR_EXT_DIR}"
echo "  Ports:"
if [ -z "${AUTH}" ]; then
  echo "    HTTP UI: ${HTTP_PORT}"
else
  echo "    HTTPS UI: ${HTTPS_PORT}"
fi
echo "    S2S RAW: ${S2S_PORT}  | Debug: ${DEBUG_PORT}"

# Remove existing container if present
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Removing existing container: ${CONTAINER_NAME}"
  docker rm -f "${CONTAINER_NAME}" >/dev/null
fi

# Run
docker run -d --name "${CONTAINER_NAME}" \
  --network "${DOCKER_NETWORK}" \
  "${PORT_ARGS[@]}" \
  "${VOLUME_ARGS[@]}" \
  "${ENV_ARGS[@]}" \
  "${DOCKER_IMAGE}"

# Hints: use single IP
if [ -z "${AUTH}" ]; then
  echo "NiFi UI:  http://${CONTAINER_NAME}:${HTTP_PORT}/nifi"
else
  echo "NiFi UI:  https://${CONTAINER_NAME}:${HTTPS_PORT}/nifi"
  echo "Tip: set SINGLE_USER_CREDENTIALS_USERNAME/PASSWORD or check 'docker logs ${CONTAINER_NAME}' for generated credentials."
fi
echo "Site-to-Site RAW: ${S2S_PORT}"
