# Contributing

A small, focused, macOS-only flake — contributions that keep it that way are the
most welcome.

## Dev loop

```sh
nix flake check                          # build packages (shellcheck) + module eval
nix run nixpkgs#nixfmt-rfc-style -- .     # format all .nix (CI enforces this)
nix build .#packages.aarch64-darwin.secret
```

## Guidelines

- The CLIs stay POSIX-ish shell in `writeShellApplication` (shellcheck-clean under
  `set -euo pipefail`).
- No secret **values** or key **names** in code, ever — the Keychain is the only
  store; git/Nix hold neither.
- Keep the every-shell model intact (`.zshenv` + `.bash_profile` + `.bashrc` +
  `$BASH_ENV`, one-time-per-tree sentinel).
- Be honest in docs about the ambient-secrets threat model.
- Update `README.md` for user-facing changes; CI (format + build + module eval)
  must pass.
