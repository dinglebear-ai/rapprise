# Changelog

All notable changes to this project will be documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

### Changed

- Pin the shared Rust cache action to Kache 0.13.0 so hosted and self-hosted jobs use the same stabilized daemon protocol.
- Bind the production MCP port only to DOOKIE's Tailscale and LAN addresses instead of every host interface.

## [0.3.0](https://github.com/dinglebear-ai/rapprise/compare/v0.2.3...v0.3.0) (2026-08-04)


### Added

* **release:** publish canonical MCP Registry metadata ([#30](https://github.com/dinglebear-ai/rapprise/issues/30)) ([0c16453](https://github.com/dinglebear-ai/rapprise/commit/0c16453ba40e399d24bcfe6e6f5acc7ff52be6a3))


### Fixed

* **release:** bind recovery provenance to tags ([#32](https://github.com/dinglebear-ai/rapprise/issues/32)) ([3c6f477](https://github.com/dinglebear-ai/rapprise/commit/3c6f477759c3e023cdc3bf81518fc800bbe229d9))
* **release:** grant npm OIDC permission ([#27](https://github.com/dinglebear-ai/rapprise/issues/27)) ([5b12e5a](https://github.com/dinglebear-ai/rapprise/commit/5b12e5a350f4c5d5d8849104d082b57bab30a0b2))
* **release:** upload recovery assets without metadata mutation ([#28](https://github.com/dinglebear-ai/rapprise/issues/28)) ([7367c37](https://github.com/dinglebear-ai/rapprise/commit/7367c37c3ec0f47de5f8d82ba2548b9d49164c96))

## [0.2.3](https://github.com/dinglebear-ai/rapprise/compare/v0.2.2...v0.2.3) (2026-08-03)


### Fixed

* **ci:** preserve existing Kache config ([#17](https://github.com/dinglebear-ai/rapprise/issues/17)) ([36826c4](https://github.com/dinglebear-ai/rapprise/commit/36826c4e50e01b52c6911bc1946c0216fe2bb5fd))
* **release:** keep root version release-please compatible ([#25](https://github.com/dinglebear-ai/rapprise/issues/25)) ([e6ddc09](https://github.com/dinglebear-ai/rapprise/commit/e6ddc09f62fc55bcc5772996f154fb29337d2b4d))
* **release:** keep xtask version release-please compatible ([#24](https://github.com/dinglebear-ai/rapprise/issues/24)) ([fd6deb4](https://github.com/dinglebear-ai/rapprise/commit/fd6deb4632535340743658cd4ebdd95b8708ef86))
* **release:** use trusted npm publisher ([#23](https://github.com/dinglebear-ai/rapprise/issues/23)) ([144b65f](https://github.com/dinglebear-ai/rapprise/commit/144b65f00cf3304525fe7ccafb2a2bcb03508fee))

## [0.2.2](https://github.com/dinglebear-ai/rapprise/compare/v0.2.1...v0.2.2) (2026-08-02)

### Fixed

* publish release assets with immutable tag-bound provenance for npm installation

## [0.2.1](https://github.com/dinglebear-ai/rapprise/compare/v0.2.0...v0.2.1) (2026-08-01)

### Fixed

* publish the npm launcher as @dinglebear/rapprise with a binary-producing release workflow.

## [0.2.0](https://github.com/jmagar/rapprise/compare/v0.1.3...v0.2.0) (2026-07-18)


### Added

* align apprise npm launcher naming ([9f28c5c](https://github.com/jmagar/rapprise/commit/9f28c5c0c75f2b6268132105103526d8d0b58cca))


### Fixed

* **ci:** allow multi-arch publication to finish ([fb73923](https://github.com/jmagar/rapprise/commit/fb739236923b80510d1b0de807a6d25f25e31c6a))
* **ci:** correct Docker QEMU action pin ([d0b38c5](https://github.com/jmagar/rapprise/commit/d0b38c53553427d6bf36979e20115174802eeecb))
* **ci:** switch OpenWiki to local openai-compatible proxy ([65fd327](https://github.com/jmagar/rapprise/commit/65fd32746f60c57896380a43e7cdbe8dbe0e35a3))
* remediate comprehensive repository review ([#5](https://github.com/jmagar/rapprise/issues/5)) ([a8f31ef](https://github.com/jmagar/rapprise/commit/a8f31efa65309e671b6e7d521f4d6ab52e33d6eb))
* route rust builds through sccache wrapper ([f34fcd1](https://github.com/jmagar/rapprise/commit/f34fcd1fb6810ee83f3511b740affc6078fd7c0b))
* **security:** update cmov for AArch64 correctness ([f3adde2](https://github.com/jmagar/rapprise/commit/f3adde2af113491f1e46576ec5153f60fa681f6d))

## [Unreleased]

### Fixed

- Require release recovery workflows to run at the immutable release tag ref so
  GitHub provenance binds npm-downloaded assets to the released source commit.

### Changed

- Standardized package/repo identity on `apprise-rmcp`, executable paths on
  `rapprise`, HTTP MCP on `40050`, and registry identity on
  `ai.dinglebear/apprise-rmcp`.
- Defined one coupled version for crate, npm, registry, tag, and native assets.
- Defined the plugin as bundled stdio with direct bundled-binary setup hooks.
- Published canonical auth, configuration, platform, and installer-trust docs.

### Removed

- Removed unsupported plugin options and the stale tracked `.claude/plugins` copy.

## [0.1.1] — 2026-06-01

### Changed

- Plugin hooks call `${CLAUDE_PLUGIN_ROOT}/bin/rapprise setup plugin-hook`
  directly. Plugin data remains in the canonical resolver selected by
  `APPRISE_HOME`, `CLAUDE_PLUGIN_DATA`, or the host/container default; no
  data migration or copy is performed.

### Removed

- `plugins/apprise/hooks/plugin-setup.sh` — the wrapper was a pure env-mapping middleman now handled by the binary's `setup plugin-hook` command.

## [0.1.0] — 2026-05-13

### Added

- Initial release of `apprise-mcp`
- `AppriseClient` HTTP REST client for the Apprise API
  - `notify(tag, title, body, type)` — POST /notify/{tag}
  - `notify_all(title, body, type)` — POST /notify
  - `notify_url(urls, title, body, type)` — stateless POST /notify/
  - `health()` — GET /health
- `AppriseService` business logic layer wrapping the client
- MCP tool `apprise` with actions: `notify`, `notify_url`, `health`, `help`
- MCP prompt `send_alert` for guided critical alert sending
- CLI: `notify`, `notify-url`, `health` subcommands
- HTTP MCP server (axum + rmcp streamable HTTP transport)
- stdio MCP transport
- `NotifyType` enum: `info`, `success`, `warning`, `failure`
- Config loading from `config.toml` + environment variables
  - `APPRISE_URL`, `APPRISE_TOKEN`
  - `APPRISE_MCP_HOST`, `APPRISE_MCP_PORT`, `APPRISE_MCP_TOKEN`
- Integration tests: stub-based graceful failure tests for all service methods
- Unit tests: `NotifyType` parsing, config defaults, bind address
