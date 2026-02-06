# NiFi Docker: Build, Run, and Test Custom Python/NAR Processors

## Dockerfile analysis
- Base: `bellsoft/liberica-openjdk-debian:${IMAGE_TAG}` (JDK from Maven).
- NiFi/Toolkit: Downloaded and verified from `${MIRROR_BASE_URL}` with checksums from `${BASE_URL}` using `${NIFI_VERSION}`.
- User/Dirs:
  - Creates `nifi` user (`UID/GID` build-args).
  - `NIFI_HOME=/opt/nifi/nifi-current`, `NIFI_TOOLKIT_HOME=/opt/nifi/nifi-toolkit-current`.
  - Pre-creates repositories and extension dirs:
    - `${NIFI_HOME}/python_extensions`
    - `${NIFI_HOME}/nar_extensions`
- Tools: `jq`, `xmlstarlet`, `procps`, `python3`, `python3-venv`, `uv` installer.
- Volumes: logs, conf, repositories, `python_extensions`, `nar_extensions`, state.
- Ports: `8443` (HTTPS UI), `10000` (S2S), `8000` (aux).
- Entrypoint: `../scripts/start.sh` relative to `${NIFI_HOME}`.

## Build the image
1. Set the desired NiFi tag in `DockerImage.txt`, e.g.:
   ```
   apache/nifi:2.6.0
   ```
2. Build:
   ```
   ./dockerhub/DockerBuild.sh
   ```
   Optional args:
   ```
   ./dockerhub/DockerBuild.sh <UID> <GID> <MIRROR> <BASE> <DISTRO_PATH>
   ```
   - `MIRROR` defaults to `https://archive.apache.org/dist`
   - `BASE` defaults to `MIRROR`
   - `DISTRO_PATH` defaults to the version from `DockerImage.txt`

## Run the container
Use the helper script (exposes ports and mounts extensions when provided):
```
./dockerhub/DockerRun.sh
```
- Container name: `nifi-<version>` (e.g., `nifi-2.6.0`)
- Ports: `8443`, `10000`, `8000`

Mount host extension directories (only if they exist):
```
export HOST_PY_EXT_DIR=/path/to/python_extensions
export HOST_NAR_EXT_DIR=/path/to/nar_extensions
./dockerhub/DockerRun.sh
```
Mount points:
- Host `${HOST_PY_EXT_DIR}` -> Container `${NIFI_HOME}/python_extensions`
- Host `${HOST_NAR_EXT_DIR}` -> Container `${NIFI_HOME}/nar_extensions`

Tip: The script defaults `HOST_PY_EXT_DIR` to your example path below.

## Purpose of python_extensions and nar_extensions
- `python_extensions`: Loose/development-style Python processor packages and modules. NiFi scans this directory at startup to register Python-based processors available via its Python integration.
- `nar_extensions`: Prebuilt NAR bundles (Java-based processors and, where applicable, bundles that may include Python integration artifacts). NiFi loads NARs from here during classpath initialization.

Use `python_extensions` for rapid iteration of Python processors. Use `nar_extensions` for distributing compiled/bundled extensions.

## Example: nifi-py4j-extension-bundle
Assuming your host path:
```
/home/ubuntu/src/james/nifi/nifi-extension-bundles/nifi-py4j-extension-bundle/nifi-python-test-extensions/src/main/resources/extensions
```
Run with mounts:
```
export HOST_PY_EXT_DIR=/home/ubuntu/src/james/nifi/nifi-extension-bundles/nifi-py4j-extension-bundle/nifi-python-test-extensions/src/main/resources/extensions
export HOST_NAR_EXT_DIR=/home/ubuntu/src/james/nifi/nifi-extension-bundles/nifi-py4j-extension-bundle/nar
./dockerhub/DockerRun.sh
```
Notes:
- `HOST_PY_EXT_DIR` default in the script already points to the above `extensions` path.
- If you build NARs from the bundle, set `HOST_NAR_EXT_DIR` to the directory containing those NAR files.

## Verify and test inside the container
- Confirm mounts:
  ```
  docker exec -it nifi-2.6.0 bash
  ls -la /opt/nifi/nifi-current/python_extensions
  ls -la /opt/nifi/nifi-current/nar_extensions
  ```
- Check logs for extension loading:
  ```
  tail -f /opt/nifi/nifi-current/logs/nifi-app.log
  ```
- Open NiFi UI:
  - https://localhost:8443
  - Add processors from your Python/NAR extensions using the UI search.
- Iterate:
  - Update code on host, then `docker restart nifi-2.6.0` to rescan extensions.

## Troubleshooting
- Version mismatch: Ensure NARs and Python extensions target the NiFi version in your image.
- Structure: Python extensions must have the expected metadata/module layout; NARs must be valid bundles.
- Permissions: Mounted directories must be readable by the `nifi` user.
- Logs: Use `nifi-app.log` to diagnose classloading/import errors.
