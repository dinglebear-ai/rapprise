#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"

python3 <<'PY'
import datetime, re
from pathlib import Path

errors = []
workflow_dir = Path(".github/workflows")
for workflow in sorted(workflow_dir.glob("*.yml")):
    text = workflow.read_text()
    for line_no, line in enumerate(text.splitlines(), 1):
        match = re.search(r"\buses:\s*([^\s]+)", line)
        if not match or match.group(1).startswith("./"):
            continue
        ref = match.group(1).rsplit("@", 1)[-1]
        if not re.fullmatch(r"[0-9a-f]{40}", ref):
            errors.append(f"{workflow}:{line_no}: external Action is not pinned to a full commit SHA")

docker = (workflow_dir / "docker-publish.yml").read_text()
for required in ["workflow_run:", "exit-code: \"1\"", "actions/attest-sbom@"]:
    if required not in docker:
        errors.append(f"docker-publish.yml: missing policy marker {required!r}")
scan_amd64 = docker.find("Blocking AMD64 vulnerability scan")
login = docker.find("Log in only after")
push = docker.find("Push scanned platform images")
if not (0 <= scan_amd64 < login < push):
    errors.append("docker-publish.yml: the amd64 scan must precede registry login and push")
if "workflows: [CI, Release]" not in docker or "release:" in docker.split("permissions:", 1)[0]:
    errors.append("docker-publish.yml: publication must follow successful CI or Release workflows, not a direct release event")
for marker in ["workflow_run.event == 'push'", "workflow_run.head_repository.full_name == github.repository", "git merge-base --is-ancestor HEAD origin/main"]:
    if marker not in docker:
        errors.append(f"docker-publish.yml: privileged workflow_run is missing trust gate {marker!r}")

release = (workflow_dir / "release.yml").read_text()
if "workflow_dispatch:" in release:
    errors.append("release.yml: provenance-bearing releases must not run from an ambiguous manual ref")
preflight = release.find("preflight:")
build = release.find("build:")
if preflight < 0 or build < preflight or "needs: [release-meta, preflight]" not in release:
    errors.append("release.yml: build/publish jobs must depend on complete preflight")
if "NODE_AUTH_TOKEN" in release or "NPM_TOKEN" in release:
    errors.append("release.yml: npm publication must use trusted publishing, not a long-lived token")

audit = Path(".cargo/audit.toml").read_text()
expiry = re.search(r"expires (\d{4}-\d{2}-\d{2})", audit)
if "RUSTSEC-2023-0071" in audit and (not expiry or datetime.date.today() >= datetime.date.fromisoformat(expiry.group(1))):
    errors.append(".cargo/audit.toml: RSA advisory exception is missing an active expiry")
inventory = Path("docs/INVENTORY.md").read_text()
if expiry and f"expires on {expiry.group(1)}" not in inventory:
    errors.append("docs/INVENTORY.md: advisory expiry must match .cargo/audit.toml")

for installer in [Path("install.sh"), Path("scripts/install.sh"), Path("packages/apprise-rmcp/scripts/install.js")]:
    text = installer.read_text()
    for marker in ["sha256", "timeout", "redirect"]:
        if marker.lower() not in text.lower():
            errors.append(f"{installer}: missing installer trust marker {marker}")
    for marker in ["attestation", "signer-workflow", "source-ref"]:
        if marker not in text:
            errors.append(f"{installer}: missing provenance policy marker {marker}")

if errors:
    raise SystemExit("\n".join(f"ERROR: {error}" for error in errors))
print("CI supply-chain policy checks passed")
PY
