# apprise-rmcp

Apprise notifications over MCP and CLI with authenticated stdio and HTTP transports.

It exposes one MCP tool, `apprise`, plus the `rapprise` CLI. Agents can send
tagged notifications through a preconfigured Apprise server, run one-off
Apprise URL sends, and check upstream health through stdio MCP, Streamable HTTP
MCP, or direct shell commands.

**30-second path:** run `npx -y @dinglebear/rapprise health --json` -> start loopback
HTTP with `APPRISE_MCP_HOST=127.0.0.1 npx -y @dinglebear/rapprise serve` -> call
`tools/call` with `{"action":"health"}`.

**Status:** operational RMCP upstream-client server. Write-capable; notification
sends are intentional side effects. HTTP MCP supports loopback dev mode, static
bearer tokens, and Google OAuth through `lab-auth`.

**Not for:** replacing Apprise API, storing notification destinations in this
repo, scheduling reminders, building a generic webhook relay, multi-tenant
isolation, or passing upstream Apprise bearer tokens through MCP tool arguments.

## Contents

- [Naming](#naming)
- [Capabilities And Boundaries](#capabilities-and-boundaries)
- [Install](#install)
- [Quickstart](#quickstart)
- [Client Configuration](#client-configuration)
- [Runtime Surfaces](#runtime-surfaces)
- [MCP Tool Reference](#mcp-tool-reference)
- [CLI Reference](#cli-reference)
- [Configuration](#configuration)
- [Authentication](#authentication)
- [Safety And Trust Model](#safety-and-trust-model)
- [Architecture](#architecture)
- [Distribution Contract](#distribution-contract)
- [Development](#development)
- [Verification](#verification)
- [Deployment](#deployment)
- [Troubleshooting](#troubleshooting)
- [Related Servers](#related-servers)
- [Documentation](#documentation)
- [License](#license)

## Naming

| Surface | This repo |
|---|---|
| Repository | `apprise-rmcp` |
| Rust crate | `apprise-mcp` |
| Binary / CLI | `rapprise` |
| npm package | `@dinglebear/rapprise` |
| npm binary aliases | `apprise-rmcp`, `rapprise` |
| MCP tool | `apprise` |
| Config home | `~/.apprise` on hosts, `/data` in containers |
| Env prefixes | `APPRISE_*`, `APPRISE_MCP_*`, `APPRISE_RMCP_*` for npm launcher controls |

The repo and npm package use the RMCP family name, while the shipped binary uses
the short Rust CLI name `rapprise`.

## Capabilities And Boundaries

- Send notifications through tags configured in the upstream Apprise API server.
- Send one-off notifications to Apprise URL schemas with `notify_url`.
- Check upstream Apprise API health.
- Expose the `send_alert` prompt for critical alert workflows.
- Provide setup and doctor commands for local plugin/runtime checks.

| This repo owns | Apprise owns | Explicitly out of scope |
|---|---|---|
| MCP/CLI projection, request validation, auth policy, response shaping, setup checks, and transport wiring. | Notification delivery, configured destinations, tags, delivery backend credentials, upstream API semantics. | Destination storage, scheduling, retry policy beyond upstream behavior, multi-tenant sandboxing, arbitrary webhook relay behavior. |

## Install

| Path | Command | Best for | Notes |
|---|---|---|---|
| npm / npx | `npx -y @dinglebear/rapprise --help` | Linux/Windows x86_64 clients. | Verifies the release archive SHA-256 before atomic install. |
| Release installer | [Verified installer procedure](#verified-release-installer) | Linux x86_64 without Node. | Verifies checksum and offline provenance before executing installer code. |
| Docker / Compose | `docker compose up -d` | Shared HTTP MCP deployments. | Reads `.env` and exposes container port `40050`. Needs the external network first — see [Deployment](#docker--compose). |
| Build from source | `cargo build --release` | Development and audits. | Produces `target/release/rapprise`. |
| Plugin | `just build-plugin && claude plugin install ./plugins/apprise` | Claude Code from this checkout. | Bundled `rapprise` stdio plugin. Ships no hooks. |

Releases publish SHA-256 files and offline GitHub build-provenance bundles. The
installers verify both the checksum and provenance identity with GitHub CLI 2.68+.
The npm launcher supports x86_64 Linux and Windows release assets.

### npm / npx

Run the stdio MCP server or CLI without a manual binary install:

```bash
npx -y @dinglebear/rapprise --help
npx -y @dinglebear/rapprise mcp
npx -y @dinglebear/rapprise health --json
```

The npm package downloads `rapprise` during `postinstall`. Override download
behavior only when testing packaging:

| Variable | Purpose |
|---|---|
| `APPRISE_RMCP_SKIP_DOWNLOAD=1` | Skip postinstall binary download. |
| `APPRISE_RMCP_VERSION` or `APPRISE_RMCP_BINARY_VERSION` | Select the GitHub Release tag. |
| `APPRISE_RMCP_REPO` | Select the GitHub repo used for release downloads. |
| `APPRISE_RMCP_RELEASE_BASE_URL` | Select a custom release base URL. |

Verified binary installation is fail-closed and pins the repository, release
workflow, and source tag. Install `gh` 2.68 or newer before using npm or the
release installer.

### Verified Release Installer

Download the installer and its verification material without executing it,
then verify both integrity and provenance before running it:

Replace `version` with the release tag you want; `v0.2.0` is current.

```bash
version=v0.2.0
base="https://github.com/dinglebear-ai/rapprise/releases/download/${version}/rapprise-installer.sh"
curl -fsSLO "$base"
curl -fsSLO "$base.sha256"
curl -fsSLO "$base.sigstore.json"
sha256sum --check rapprise-installer.sh.sha256
gh attestation verify rapprise-installer.sh \
  --repo dinglebear-ai/rapprise \
  --bundle rapprise-installer.sh.sigstore.json \
  --signer-workflow dinglebear-ai/rapprise/.github/workflows/release.yml \
  --source-ref "refs/tags/${version}" \
  --deny-self-hosted-runners
APPRISE_RMCP_VERSION="$version" bash rapprise-installer.sh
```

The `--repo` and `--signer-workflow` values must match the identity recorded in
the attestation at build time. Releases cut before the repository moved to the
`dinglebear-ai` org are attested as `jmagar/rapprise`; use `dinglebear-ai/rapprise`
for releases cut afterwards.

The npm launcher supports Windows x86_64 only when GitHub CLI 2.68+ is installed
and `gh.exe` is available on `PATH`; provenance verification is not skipped.

### Build From Source

```bash
git clone https://github.com/dinglebear-ai/rapprise
cd rapprise
cargo build --release
./target/release/rapprise --help
```

Minimum supported Rust version: 1.90. Rust edition 2021. The Cargo workspace has
two members: the root `apprise-mcp` package and `xtask`.

## Quickstart

### 1. Start Or Point At Apprise API

The default upstream is `http://localhost:8000`.

```bash
docker run --rm -p 8000:8000 caronc/apprise:latest
```

Use `APPRISE_URL` when the API server is elsewhere:

```bash
export APPRISE_URL=http://100.120.242.29:8766
```

Set `APPRISE_TOKEN` only when your Apprise API server requires bearer auth:

```bash
export APPRISE_TOKEN=...
```

### 2. Run A Safe CLI Call

```bash
npx -y @dinglebear/rapprise health --json
```

### 3. Start Loopback HTTP MCP

```bash
APPRISE_MCP_HOST=127.0.0.1 npx -y @dinglebear/rapprise serve
```

In another shell:

```bash
curl -sf http://127.0.0.1:40050/health
```

### 4. Make A First MCP Call

```bash
curl -s -X POST http://127.0.0.1:40050/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"apprise","arguments":{"action":"health"}}}'
```

## Client Configuration

### Claude Code Stdio

```json
{
  "mcpServers": {
    "apprise": {
      "command": "npx",
      "args": ["-y", "apprise-rmcp", "mcp"],
      "env": {
        "APPRISE_URL": "http://localhost:8000"
      }
    }
  }
}
```

### Claude Code HTTP

```json
{
  "mcpServers": {
    "apprise": {
      "type": "http",
      "url": "http://127.0.0.1:40050/mcp",
      "headers": {
        "Authorization": "Bearer ${APPRISE_MCP_TOKEN}"
      }
    }
  }
}
```

### Codex / Labby Gateway

Register Apprise through Labby as an HTTP upstream when sharing one long-running
server, or run it directly as stdio for local-only use.

```toml
[mcp_servers.apprise]
command = "npx"
args = ["-y", "apprise-rmcp", "mcp"]
```

### Generic MCP JSON

```json
{
  "command": "rapprise",
  "args": ["mcp"],
  "env": {
    "APPRISE_URL": "http://localhost:8000"
  }
}
```

Do not put `APPRISE_TOKEN`, OAuth secrets, SSH keys, passwords, or upstream
bearer tokens in MCP tool arguments. Use env, config files, or the MCP client's
secret storage.

## Runtime Surfaces

| Surface | Status | Entry point | Purpose |
|---|---:|---|---|
| MCP stdio | Supported | `rapprise mcp`, `npx -y @dinglebear/rapprise mcp` | Local child-process MCP clients. |
| MCP HTTP | Supported | `rapprise serve`, `POST /mcp` | Streamable HTTP MCP for local or shared server deployments. |
| Liveness | Supported | `GET /health` | Always unauthenticated. |
| Readiness / status | Supported | `GET /ready`, `GET /status` | Behind the same auth layer as `/mcp`. |
| OAuth discovery | Conditional | `/mcp/.well-known/*` and `lab-auth` routes | Mounted only when `auth_mode = oauth`. |
| CLI | Supported | `rapprise <command>` | Scriptable parity and debugging. |
| Prompt | Supported | `send_alert` | Reusable critical-alert workflow. |
| REST API | Not shipped | N/A | Apprise API already owns the REST API. |
| Web UI | Not shipped | N/A | Apprise API already owns the web UI. |

## MCP Tool Reference

One MCP tool is exposed: `apprise`. Pass the required `action` argument to select
the operation.

### Read Actions

| Action | Description | Required params | Optional params |
|---|---|---|---|
| `health` | Check Apprise API server health. | none | none |
| `status` | Return authenticated deployment and runtime status. | none | none |
| `help` | Return built-in markdown tool help. | none | none |

### Write Actions

| Action | Description | Required params | Optional params |
|---|---|---|---|
| `notify` | Send to a configured Apprise tag, or all configured services when `tag` is omitted. | `body` | `tag`, `title`, `type` |
| `notify_url` | Send a stateless one-off notification to one or more Apprise URL schemas. | `urls`, `body` | `title`, `type` |

### Notification Types

| Type | Meaning |
|---|---|
| `info` | Informational notification. |
| `success` | Successful operation. |
| `warning` | Non-critical warning. |
| `failure` | Critical failure or error. |

### MCP Call Examples

```bash
curl -s -X POST http://127.0.0.1:40050/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"apprise","arguments":{"action":"health"}}}'
```

```json
{
  "name": "apprise",
  "arguments": {
    "action": "notify",
    "body": "Deployment succeeded",
    "tag": "ops",
    "title": "Deploy complete",
    "type": "success"
  }
}
```

Curated action summaries live here. `docs/INVENTORY.md` is the current
source of truth for complete parameters until a generated `docs/MCP_SCHEMA.md`
is added.

## CLI Reference

The CLI calls the same service methods as the MCP tool.

```bash
rapprise health [--json]
rapprise notify <body> [--tag TAG] [--title T] [--type info|success|warning|failure] [--json]
rapprise notify-url <urls> <body> [--title T] [--type info|success|warning|failure] [--json]

rapprise serve                          # Streamable HTTP MCP on :40050
rapprise serve mcp                      # same as `serve`
rapprise mcp                            # stdio MCP
rapprise doctor [--json]                # pre-flight environment validation
rapprise setup check                    # read-only audit of appdata/env
rapprise setup repair                   # idempotent: create missing setup files
rapprise setup install                  # copy this binary into ~/.local/bin
rapprise setup plugin-hook [--no-repair]

rapprise help                           # or --help / -h
rapprise --version                      # or -V
```

`--json` emits raw JSON instead of pretty-printed fields. `--help` prints the
full environment-variable reference.

## Configuration

Configuration loads from `config.toml` when present, then environment variables
override those values. On startup it loads
`${APPRISE_HOME:-~/.apprise}/.env` on hosts or `/data/.env` in containers.
See [the complete inventory](docs/INVENTORY.md).

### Upstream Variables

| Variable | Required | Description |
|---|---:|---|
| `APPRISE_URL` | no | Apprise API server base URL. Defaults to `http://localhost:8000`. |
| `APPRISE_TOKEN` | only for protected upstreams | Outbound bearer token for the upstream Apprise API. Distinct from the inbound `APPRISE_MCP_TOKEN`. |
| `APPRISE_MAX_CONCURRENT_REQUESTS` | no | Upstream request concurrency. Default `32`, bounded `1..=1024`. |
| `APPRISE_MAX_RESPONSE_BYTES` | no | Upstream response cap. Default `65536`, bounded `1..=4194304`. |
| `APPRISE_HOME` | no | Data directory. Defaults to `~/.apprise` on hosts, `/data` in containers. |

### Runtime Variables

| Variable | Default | Description |
|---|---|---|
| `APPRISE_MCP_HOST` | `0.0.0.0` | HTTP MCP bind host. |
| `APPRISE_MCP_PORT` | `40050` | HTTP MCP bind port. |
| `APPRISE_MCP_TOKEN` | empty | Static bearer token for HTTP MCP when not in loopback dev mode. |
| `APPRISE_MCP_NO_AUTH` | `false` | Disable HTTP MCP auth. Use only on loopback or behind a trusted gateway. |
| `APPRISE_MCP_AUTH_MODE` | `bearer` | Set to `oauth` for Google OAuth through `lab-auth`. |
| `APPRISE_MCP_PUBLIC_URL` | empty | Public URL for OAuth metadata and protected-resource discovery. |
| `APPRISE_MCP_GOOGLE_CLIENT_ID` | empty | Google OAuth client ID. |
| `APPRISE_MCP_GOOGLE_CLIENT_SECRET` | empty | Google OAuth client secret. |
| `APPRISE_MCP_AUTH_ADMIN_EMAIL` | empty | Initial/admin OAuth email. |
| `APPRISE_MCP_ALLOWED_HOSTS` | empty | Additional accepted HTTP Host values. |
| `APPRISE_MCP_ALLOWED_ORIGINS` | empty | Additional CORS origins for HTTP MCP. |
| `APPRISE_MCP_AUTH_ALLOWED_REDIRECT_URIS` | empty | OAuth client redirect URIs. |
| `APPRISE_MCP_AUTH_ALLOWED_EMAILS` | empty | OAuth email allowlist. |
| `APPRISE_MCP_AUTH_SQLITE_PATH` | data-dir `auth.db` | OAuth state store path. |
| `APPRISE_MCP_AUTH_KEY_PATH` | data-dir `auth-jwt.pem` | JWT signing key path. |
| `APPRISE_MCP_DISABLE_STATIC_TOKEN_WITH_OAUTH` | `true` | Forbid the static bearer token from bypassing OAuth. |
| `RUST_LOG` | `info` | Rust log filter. Stdio logs must stay off stdout. |

Token TTL and rate-limit variables (`APPRISE_MCP_AUTH_*_TTL_SECS`,
`APPRISE_MCP_AUTH_*_REQUESTS_PER_MINUTE`, `APPRISE_MCP_AUTH_MAX_PENDING_OAUTH_STATES`)
are listed in full in [`docs/INVENTORY.md`](docs/INVENTORY.md).

## Authentication

| Policy | When | Effect |
|---|---|---|
| Stdio | `rapprise mcp` | Local process trust; HTTP auth does not apply. |
| Loopback dev | loopback plus no-auth | Permits unauthenticated local HTTP. |
| Non-loopback no-auth | non-loopback plus no-auth | Invalid; startup must reject it. |
| Static bearer | bearer plus `APPRISE_MCP_TOKEN` | Require exact bearer token. |
| OAuth | issuer/client/admin settings | Require OAuth/JWT. |
| OAuth static control | disable-static true | Static token must not bypass OAuth. |

MCP scopes are `apprise:notify` and `apprise:admin`. OAuth tokens are checked
before MCP calls are dispatched.

## Safety And Trust Model

- MCP callers never provide `APPRISE_TOKEN`, OAuth secrets, static bearer tokens,
  passwords, SSH keys, or API keys as tool arguments.
- Upstream Apprise credentials are loaded from env/config only.
- `notify` is the preferred path because destinations are configured upstream
  under tags.
- `notify_url` intentionally accepts Apprise URL schemas in MCP arguments for
  one-off sends. Treat those URLs as sensitive payloads and avoid using them
  when a tagged upstream destination is available.
- Apprise API is the durable source of destination configuration; this server is
  a thin projection over that API.
- HTTP mode should not be exposed beyond loopback without bearer or OAuth auth
  plus TLS from an upstream reverse proxy.

## Architecture

```text
MCP client / CLI
       |
       v
rapprise
       |
       +-- MCP shim: JSON args -> AppriseService -> structured result
       +-- CLI shim: argv -> AppriseService -> stdout
       |
       v
AppriseService
       |
       v
AppriseClient
       |
       v
Apprise API server
       |
       v
Notification backends
```

| Path | Role |
|---|---|
| `src/app.rs` | Business service layer, response shaping, counters, and notification calls. |
| `src/apprise.rs` | Apprise API REST client. |
| `src/mcp/` | RMCP tool, prompt, schema, routes, and auth checks. |
| `src/cli.rs` | CLI parser, doctor/setup helpers, and output formatting. |
| `src/config.rs` | Env/config loading and defaults. |
| `packages/apprise-rmcp/` | npm launcher and release-binary downloader. |

Notification commands and MCP converge on `AppriseService`. The CLI also owns
setup, doctor, self-install, filesystem, and output orchestration today; it is
not a pure argument shim.

## Distribution Contract

| Artifact | File(s) | Must align with |
|---|---|---|
| Rust crate/binary | `Cargo.toml`, `Cargo.lock` | Git tag, release assets, CLI docs, install scripts. |
| npm launcher | `packages/apprise-rmcp/package.json`, `bin/rapprise.js`, `lib/platform.js`, `scripts/install.js` | GitHub Release tag and assets named `rapprise-x86_64.tar.gz` and `rapprise-windows-x86_64.tar.gz`. |
| GitHub Releases | `.github/workflows/*`, `scripts/install.sh`, `install.sh` | Package version, binary name, checksums, supported platforms. |
| Docker / Compose | `config/Dockerfile`, `docker-compose.yml`, `docker-compose.prod.yml` | Exposed port `40050`, healthcheck `/health`, env file contract. |
| MCP registry | `server.json` | Identity `ai.dinglebear/rapprise`, stdio package, version. |
| Plugin | `plugins/apprise` | Bundled `rapprise` stdio only. No hooks, no `version`, no `userConfig` in manifests. |
| Docs | `README.md`, `docs/INVENTORY.md`, `docs/QUICKSTART.md` | Current binary name, default port, action list, and env names. |

Release invariant: npm, crate, registry/server metadata, manifest, GitHub tag,
and native assets move together. Release Please owns these updates.

## Development

```bash
cargo fmt -- --check
cargo clippy --all-targets -- -D warnings
cargo test
cargo build --release
npm --prefix packages/apprise-rmcp run check
npm --prefix packages/apprise-rmcp test

# Contract checks
bash tests/docs-contract.sh              # docs, versions, and plugin invariants
bash scripts/validate-plugin-layout.sh   # or: just validate-plugin
```

`just` wraps the common loops: `just check`, `just lint`, `just fmt`,
`just test`, `just release`, `just build-plugin`, `just docker-up`,
`just health`. The plugin recipe is `build-plugin` — there is no `plugin-build`.

`Cargo.toml` declares `rmcp = "1.6.0"`, but the caret range resolves forward and
`Cargo.lock` pins **rmcp 1.7.0**. Trust the lock.

## Verification

```bash
# Binary and CLI
cargo build --release
./target/release/rapprise --version
./target/release/rapprise health --json

# HTTP health
APPRISE_MCP_HOST=127.0.0.1 ./target/release/rapprise serve
curl -sf http://127.0.0.1:40050/health

# MCP tool call
curl -s -X POST http://127.0.0.1:40050/mcp \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"apprise","arguments":{"action":"health"}}}'
```

For live notification tests, configure at least one destination in the Apprise
API server and call `notify` with its tag.

## Deployment

### Docker / Compose

`docker-compose.prod.yml` declares the `apprise-mcp` network as `external: true`,
so create it once before the first bring-up:

```bash
cp .env.example .env
$EDITOR .env
docker network create apprise-mcp
docker compose up -d
curl -sf http://127.0.0.1:40050/health
```

`docker-compose.yml` builds `apprise-mcp:dev` from `config/Dockerfile` and
extends the production service. `docker-compose.prod.yml` alone runs the
published image with `pull_policy: never`, so pull or load it first. The
container runs read-only as UID 1000 and stores app data under `/data`, normally
mounted from `${APPRISE_DATA_DIR:-${HOME}/.apprise}`. Override the published
host port with `APPRISE_MCP_HOST_PORT`.

### Reverse Proxy

Expose only `/mcp` and `/health` — plus the `lab-auth` and `/mcp/.well-known/*`
routes when running OAuth. Keep `/ready` and `/status` internal. Preserve
Streamable HTTP headers, require TLS, and configure bearer or OAuth auth before
exposing the server beyond loopback.

### Plugin

The plugin is bundled stdio and ships no Claude Code hooks — nothing runs
automatically on session start, so run setup yourself once:

```bash
just build-plugin
claude plugin install ./plugins/apprise
rapprise setup check
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `401` from `/mcp` | Missing or wrong bearer/OAuth token. | Check `APPRISE_MCP_TOKEN` and client headers, or use loopback dev mode locally. |
| CLI health fails | Apprise API is not reachable. | Check `APPRISE_URL` and the upstream Apprise API server. |
| `notify` sends nowhere | No upstream destinations match the tag. | Check configured tags in Apprise API or omit `tag` to send to all configured services. |
| `notify_url` fails | Invalid Apprise URL schema or blocked destination backend. | Test the URL with Apprise API directly and prefer configured tags for repeated use. |
| stdio MCP JSON parse errors | Logs went to stdout. | Keep protocol logs off stdout and lower `RUST_LOG` if needed. |
| npm launcher cannot find binary | Release asset download failed or was skipped. | Reinstall, check `APPRISE_RMCP_VERSION`, or build `rapprise` from source. |

## Related Servers

- [soma](https://github.com/dinglebear-ai/soma) - RMCP runtime and scaffold for provider-backed MCP servers.
- [unifi-rmcp](https://github.com/dinglebear-ai/runifi) - UniFi controller REST API bridge.
- [tailscale-rmcp](https://github.com/dinglebear-ai/rtailscale) - Tailscale API bridge for devices, users, and tailnet operations.
- [unraid](https://github.com/dinglebear-ai/unraid) - Unraid monorepo; `unraid-rs/` is the GraphQL MCP bridge (binary `runraid`).
- [gotify-rmcp](https://github.com/dinglebear-ai/rgotify) - Gotify push notification bridge for sends, messages, apps, and clients.
- [arcane-rmcp](https://github.com/dinglebear-ai/rarcane) - Arcane Docker management bridge for containers and related resources.
- [yarr](https://github.com/dinglebear-ai/yarr) - Media-stack bridge for Sonarr, Radarr, Prowlarr, Plex, and related services.
- [ytdl-rmcp](https://github.com/dinglebear-ai/rytdl) - Media download and metadata workflow server.
- [synapse-rmcp](https://github.com/dinglebear-ai/synapse) - Local Synapse workflow server for scout and flux actions.
- [cortex](https://github.com/dinglebear-ai/cortex) - Syslog and homelab log aggregation MCP server.
- [axon](https://github.com/dinglebear-ai/axon) - RAG, crawl, scrape, extract, and semantic search project.
- [labby](https://github.com/dinglebear-ai/labby) - Homelab control plane and MCP gateway project.

## Documentation

Start here:

- [`docs/QUICKSTART.md`](docs/QUICKSTART.md) - focused setup flow.
- [`docs/INVENTORY.md`](docs/INVENTORY.md) - component inventory for actions,
  CLI commands, env vars, and endpoints.
- [`docs/README.md`](docs/README.md) - docs index.
- [`server.json`](server.json) - MCP registry metadata.
- [`packages/apprise-rmcp/README.md`](packages/apprise-rmcp/README.md) - npm
  package launcher notes.

This README is curated. Generated or exhaustive catalogs should be refreshed in
their own files and treated as the source of truth for current branch details.

## License

Original Dinglebear-authored portions of this project are licensed under [AGPL-3.0-only](LICENSE). Separate commercial licensing is available for organizations that need terms outside the AGPL. Third-party material remains under its original license. See [LICENSING.md](https://github.com/dinglebear-ai/rapprise/blob/main/LICENSING.md).
