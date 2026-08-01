# apprise-rmcp agent guide

`CLAUDE.md` is canonical. `AGENTS.md` and `GEMINI.md` must symlink to it
(`ln -sf CLAUDE.md AGENTS.md`). `tests/docs-contract.sh` enforces this.

## Product contract

- Repository: `rapprise`; npm package: `@dinglebear/rapprise` (`packages/apprise-rmcp/`)
- Git remote: `git@github.com:dinglebear-ai/rapprise.git`, default branch `main`
- Rust crate/service: `apprise-mcp`
- Executable: `rapprise`
- MCP HTTP port: `40050`
- Upstream default: `http://localhost:8000` (Apprise API server, 80+ backends)
- One `apprise` tool: `notify`, `notify_url`, `health`, `status`, `help`
- Prompt: `send_alert`
- Data: `${APPRISE_HOME:-~/.apprise}` on hosts, `/data` in containers
- Registry identity: `ai.dinglebear/rapprise`

This server is a thin projection over the Apprise API. It does not store
destinations, schedule sends, or retry beyond upstream behavior.

## Workspace layout

Two-member Cargo workspace (`resolver = "3"`): the root `apprise-mcp` package
and `xtask`. Both inherit Rust 1.97.1, edition 2024, metadata, dependencies,
and fleet lints from the workspace tables. `rmcp` is exactly pinned to
`3.0.0-beta.2`, matching `Cargo.lock`.

`lab-auth` comes from `github.com/dinglebear-ai/labby.git` at a pinned rev.

## Architecture

`src/apprise.rs` owns Apprise HTTP; `src/app.rs` owns notification logic;
`src/mcp/` owns MCP contracts and routing. Notification CLI parsing delegates
to `AppriseService`, while setup, doctor, self-install, filesystem operations,
and output formatting currently live in `src/cli.rs`. HTTP auth is assembled
in `src/main.rs` and `src/mcp/routes.rs`.

Use sibling `foo.rs` plus `foo/`, never `foo/mod.rs`.

## Surfaces

| Entry point | Transport |
|---|---|
| `rapprise mcp` | stdio MCP |
| `rapprise serve`, `rapprise serve mcp` | Streamable HTTP MCP on `:40050` |
| `rapprise <command>` | CLI |

CLI commands: `notify`, `notify-url`, `health`, `doctor`, `help`,
`setup check`, `setup repair`, `setup install`, `setup plugin-hook [--no-repair]`,
plus `--json`, `--help`/`-h`, `--version`/`-V`.

HTTP routes: `POST /mcp`, `GET /health` (always unauthenticated),
`GET /ready` and `GET /status` (behind the auth layer), plus the `lab-auth`
OAuth routes and `/mcp/.well-known/*` discovery when `auth_mode = oauth`.
Unmatched paths return a JSON `404`. Request bodies are size-limited.

## Build and checks

```bash
cargo fmt -- --check
cargo clippy --all-targets -- -D warnings
cargo check
cargo test
cargo build --release
npm --prefix packages/apprise-rmcp test
npm --prefix packages/apprise-rmcp run check
bash tests/docs-contract.sh
bash scripts/validate-plugin-layout.sh   # or: just validate-plugin
```

`just` recipes wrap most of these: `just check`, `just lint`, `just test`,
`just release`, `just build-plugin`, `just health`, `just docker-up`.
Note the recipe is `build-plugin`, not `plugin-build`.

## Plugin contract

`plugins/apprise` is the only plugin source and is a bundled stdio plugin.
`.mcp.json` launches `${CLAUDE_PLUGIN_ROOT}/bin/rapprise mcp`. Build the bundled
binary with `just build-plugin` before installing from a checkout.

**The plugin ships no Claude Code hooks.** There is no `hooks/` directory and
the manifest declares no `hooks` key, so nothing runs on `SessionStart` or
`ConfigChange`. Setup is operator-invoked: `setup check` is read-only,
`setup repair` is idempotent, and `setup plugin-hook --no-repair` audits without
mutating appdata. `setup plugin-hook` remains a supported CLI entry point for
external automation even though no bundled hook calls it.
`tests/docs-contract.sh`, `scripts/validate-plugin-layout.sh`, and
`tests/setup_contract.rs` all assert the hooks stay absent.

Manifests do not advertise deployment options and must not declare `version` or
`userConfig`. Configure env or the canonical data-directory `.env`. Do not add
Docker/systemd/service bootstrap to the plugin or track a second plugin under
`.claude/plugins`.

## Auth invariants

Stdio trusts the local parent process. HTTP no-auth is loopback-only — a
non-loopback bind with no-auth must be rejected at startup. Bearer mode uses
`APPRISE_MCP_TOKEN`; OAuth requires issuer/client/admin state and must not
accept the static token when `disable_static_token_with_oauth=true`.
MCP scopes are `apprise:notify` and `apprise:admin`.

`APPRISE_TOKEN` is a distinct **outbound** credential for a protected upstream
Apprise API — never confuse it with the inbound `APPRISE_MCP_TOKEN`.

Secrets never travel as MCP tool arguments. Config precedence is
`config.toml` → `${APPRISE_HOME:-~/.apprise}/.env` (`/data/.env` in containers)
→ process env, last wins. `docs/INVENTORY.md` is the full env-var table.

## Release invariant

Crate, npm launcher, registry package, `server.json`, release manifest, tag,
and assets use one coupled version. Release Please owns version changes — do not
hand-edit versions. `tests/docs-contract.sh` cross-checks all six.

Releases publish SHA-256 sums and GitHub build-provenance bundles; installers
verify both and require GitHub CLI 2.68+.

Use `bd` for all tracking: run `bd prime`, claim before editing, and close
completed work.
