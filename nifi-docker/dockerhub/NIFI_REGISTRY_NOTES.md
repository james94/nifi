NiFi Registry support notes

Finding
- Current Dockerfile and shell scripts download and configure NiFi only.
- No NiFi Registry server binaries are included; scripts do not set Registry server properties.
- The nifi-registry client NAR present in NiFi enables client features (e.g., external resource provider), not the Registry server.

Recommended structure (separate project for Registry)
- Proposed subfolders (to create later):
  - /home/ubuntu/src/james/nifi/nifi-docker/dockerhub/nifi         # existing NiFi image
  - /home/ubuntu/src/james/nifi/nifi-docker/dockerhub/registry     # NiFi Registry image
    - Dockerfile
    - DockerBuild.sh
    - DockerRun.sh

Example: run official NiFi Registry container
- Shared network (matches NiFi’s DockerRun.sh):
  - docker network create fleet-net
- Start Registry (default HTTP on 18080):
  - docker run -d --name nifi-registry --network fleet-net -p 18080:18080 apache/nifi-registry:latest

Integrate NiFi with Registry (NiFi UI)
- In NiFi UI: Versioned Flows > Manage Registries > Add Registry
  - URL: http://nifi-registry:18080/nifi-registry
- Create a Bucket in Registry UI, then version your process group to that bucket.

Ports and security
- Registry default port: 18080 (HTTP). HTTPS requires separate TLS config in the Registry container.
- NiFi can be HTTP (8080) or HTTPS (8443) based on AUTH. Both can talk to Registry over HTTP or HTTPS depending on its setup.

NiFi Registry DockerRun.sh usage and integration

- Scope: The NiFi Registry Dockerfile and scripts build/run NiFi Registry only; NiFi and Registry run as separate containers.
- Smooth deployment:
  - Run the script:
    - /home/ubuntu/src/james/nifi/nifi-registry/nifi-registry-core/nifi-registry-docker/dockerhub/DockerRun.sh
  - Creates or uses Docker network 'fleet-net' for NiFi ⇄ Registry communication.
  - Mounts persistent directories:
    - flow_storage, extension_bundles, database (H2)
  - Exposes:
    - HTTP 18080 (default)
    - HTTPS 18443 (if AUTH set and secure.sh config provided)

Integrate with NiFi
- In NiFi UI: Versioned Flows -> Manage Registries -> Add Registry
  - URL: http://nifi-registry:18080/nifi-registry
- Create a Bucket in Registry UI, then start versioning process groups to that bucket.

Notes
- To enable TLS for Registry, set AUTH=tls and provide KEYSTORE/TRUSTSTORE env variables; the secure.sh script handles HTTPS and identity providers.
- Keep NiFi and NiFi Registry on the same Docker network (fleet-net) so hostnames resolve between containers.

Conclusion
- Current NiFi Dockerfile does not include NiFi Registry. Use a separate Registry container and attach both to the same Docker network.
