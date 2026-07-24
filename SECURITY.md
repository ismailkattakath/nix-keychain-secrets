# Security Policy

## The model (important)

`keychain-secrets` exports your registered Keychain secrets into **every shell**
in a process tree — by design. Consequence: **any process in that tree, including
a compromised dependency or an AI coding agent, can read every exported value via
`env`.** This is the right trade-off for *laptop/dev API keys* and the wrong one
for high-value, server, or shared-machine secrets — use `sops-nix`/`agenix`/
1Password for those.

- Values rest in the macOS login Keychain (encrypted at rest) and in process
  memory. Neither the values nor the key names touch the Nix store or git.
- The loader reads the Keychain at most once per process tree; a locked Keychain
  leaves the tree un-cached so a later shell retries.

## Reporting a vulnerability

Please open a **private** security advisory via GitHub
("Security" → "Report a vulnerability"), or contact the maintainer directly.
Do not file public issues for undisclosed vulnerabilities.
