NiFi ⇄ MiNiFi C++ Site-to-Site (S2S) setup analysis and changes

Summary of original behavior
- start.sh set:
  - nifi.remote.input.socket.port=10000 (RAW S2S port)
  - nifi.remote.input.host=$HOSTNAME
  - nifi.remote.input.secure=true (secure S2S)
  - nifi.web.https.port/host (HTTPS UI)
- secure.sh (invoked when AUTH=tls|ldap|oidc) enforced TLS:
  - Configured keystore/truststore and HTTPS UI
  - Set nifi.remote.input.secure=true
- Result: Intended secure S2S + HTTPS. Without AUTH, start.sh still set HTTPS values but no keystore, which can cause startup issues.

What changed to enable easy unsecured S2S by default
- Default to HTTP + unsecured S2S when AUTH is unset:
  - Set nifi.web.http.port=8080 and host, clear HTTPS values.
  - Set nifi.remote.input.secure=false.
  - Set nifi-toolkit baseUrl to http://host:8080.
- Keep secure mode behavior intact when AUTH is set:
  - secure.sh still configures HTTPS + secure S2S and toolkit keystores.
- Expose and map HTTP port 8080 in Dockerfile and DockerRun.sh.

Files updated
- sh/start.sh:
  - Add unsecured branch (HTTP + unsecured S2S) when AUTH is not set.
  - Remove unconditional HTTPS setup and toolkit keystore/truststore in unsecured path.
  - Toolkit baseUrl now uses http or https depending on AUTH.
- Dockerfile:
  - EXPOSE 8080 added.
- DockerRun.sh:
  - Added -p 8080:8080 and printed port hints.

How to run
- Unsecured (default):
  - Do not set AUTH. Container will expose HTTP on 8080 and S2S RAW on 10000.
  - Access UI: http://<host>:8080
  - Configure MiNiFi C++ to connect via RAW S2S to <host>:10000 (nifi.remote.input.host/port).
- Secured:
  - Set AUTH=tls (or ldap/oidc) and provide keystore/truststore env vars; secure.sh handles HTTPS + secure S2S.
  - Access UI: https://<host>:8443
  - S2S secure=true.

Notes
- RAW S2S port (10000) is enabled and mapped in all cases.
- For HTTP-based S2S (if desired later), additional NiFi properties may be required; current defaults target RAW S2S for simplicity.

NiFi 2.x templates vs flow export

- Finding: No scripts or Dockerfile settings here disable the “Save as Template” feature. In NiFi 2.x, legacy Templates were removed from the UI. Export is performed using:
  - UI: Download Flow Definition from the top menu.
  - REST: GET http://<host>:8080/nifi-api/flow/process-groups/root to download the current flow JSON.
  - Versioning: NiFi Registry (external service) for Versioned Flows.

How to download the current flow
- From the container:
  - docker exec -it nifi-2.6.0 curl -s http://localhost:8080/nifi-api/flow/process-groups/root > /tmp/flow.json
- From the host:
  - curl -s http://<host>:8080/nifi-api/flow/process-groups/root > flow.json
- This returns the flow definition JSON you can save and re-import.

Notes
- No changes needed to start.sh, secure.sh, Dockerfile, or other scripts to enable “save.” The UI button for templates is absent by design in NiFi 2.x.
- For full versioning, run NiFi Registry and use the Versioned Flows UI to commit and export versions.

<!-- 
GitHub Copilot:

Prompt:

Can you analyze the following files I have attached and explain if they enable "Site to Site Communication" between NiFi and MiNiFi C++? I will be building and deploying the NiFi docker image/container and then later from MiNiFi C++ github repo, building and deploying that container. It looks like these .sh scripts when building and deploying NiFi setup secure site to site correct, but for simplicity I would like to setup regular unsecured site to site for easy initial communication between NiFi and MiNiFi, can you help me make the updates? Can you update the "RESEARCH.md" file with notes of the updates you make to the necessary files I have attached?

Response:


Here’s the plan to default NiFi to unsecured Site-to-Site for easy initial NiFi ⇄ MiNiFi C++ communication, while keeping secure mode available when AUTH is set:

Step-by-step

1. Default NiFi to HTTP and unsecured S2S when AUTH is unset:

- Set nifi.web.http.port/host and clear https values.
- Set nifi.remote.input.secure=false.
- Point toolkit baseUrl to http://...

2. Keep secure mode when AUTH is set (tls/ldap/oidc) with existing secure.sh.

3. Remove unconditional HTTPS assumptions from start.sh.

4. Expose and map port 8080 for HTTP.

5. Document changes and how to run in RESEARCH.md.

Changes by file

start.sh

Default to HTTP + unsecured S2S when AUTH is not set. Only configure HTTPS and secure S2S when AUTH is set and secure.sh runs. Also set nifi-toolkit baseUrl scheme based on AUTH and stop setting keystore/truststore in unsecured mode.

Edited: start.sh+15-0

Dockerfile

Expose HTTP 8080 for unsecured UI access. No other changes.

Edited
Dockerfile+1-1
DockerRun.sh
Map port 8080 for unsecured HTTP UI access and show it in the output.

Edited
DockerRun.sh+3-1
RESEARCH.md
Notes describing what the scripts did before and the changes to support unsecured S2S by default.

Edited
RESEARCH.md+46-1
Explanation of Site-to-Site enablement

Yes, the original scripts enabled S2S using RAW port 10000 with secure=true by default and HTTPS UI. After these changes, unsecured S2S is enabled by default (secure=false, HTTP UI on 8080), with secure mode still available when AUTH is set.

 -->
