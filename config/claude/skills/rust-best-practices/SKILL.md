---
name: rust-best-practices
description: Use whenever creating, modifying, or releasing a Rust crate or workspace (a Cargo.toml is present or about to be created). Covers keeping Cargo.lock and the README in sync with the code, and making GitHub releases line up cleanly with crates.io publishing. Triggers on "cargo", "crate", "Cargo.toml", "Rust project", "cut a release", "publish to crates.io", "GitHub release".
---

# Rust project hygiene

Three things repeatedly go stale or get botched in Rust projects if
nobody enforces them deliberately. Check all three whenever you touch a
Rust crate's dependencies, public surface, or cut a release.

## Cargo.lock

- If the crate (or any crate in the workspace) produces a binary,
  **commit `Cargo.lock`**. It's the only thing that makes CI, `cargo
  install --locked`, and Nix builds (`buildRustPackage` with
  `cargoLock.lockFile`) reproducible. Don't gitignore it.
- For a workspace member that's a pure library with no binary anywhere
  in the workspace, committing `Cargo.lock` is optional by convention
  (downstream consumers resolve their own) — but committing it anyway
  costs nothing and keeps your own CI/tests reproducible, so default to
  committing unless there's a specific reason not to.
- Whenever you add, remove, or bump a dependency in `Cargo.toml`, run
  `cargo build` (or `cargo update -p <pkg>`) and commit the resulting
  `Cargo.lock` diff **in the same commit** as the `Cargo.toml` change —
  never let them drift apart across commits.
- Never hand-edit `Cargo.lock`.

## README

- Treat README code examples as load-bearing, not decorative. When a
  public API, CLI flag, or subcommand changes, update the README's
  usage examples in the same change — and actually run the example
  (`cargo run --example ...`, or paste the snippet into a scratch file)
  before committing it, rather than trusting it compiles from memory.
- Keep install instructions (`cargo install`/`cargo build`/`nix build`)
  and CLI usage synced with what the code currently does. A stale
  README is worse than no README, since it actively misleads.
- If the project is a workspace, keep the "project layout" section
  (crate names, paths, responsibilities) in sync whenever crates are
  added, renamed, split, or removed.

## GitHub releases that line up with crates.io

- Tag releases `vX.Y.Z` matching the exact version in `Cargo.toml`
  (including inherited `version.workspace = true`). Bump the version,
  run `cargo build` to refresh `Cargo.lock`, commit both together, and
  only then tag that commit — never tag before the version-bump commit
  exists, or the tag won't correspond to a buildable, publishable state.
- **Path-only workspace dependencies block `cargo publish`.** If crate A
  depends on crate B via `{ path = "../b" }` with no `version`, crates.io
  rejects A's publish because it can't resolve B there. Before publishing
  any crate in a workspace, every internal `path` dependency also needs
  a `version` (e.g. `{ path = "../b", version = "0.1" }`, or
  `version.workspace = true` alongside the path).
- Publish dependencies before dependents (`cargo publish -p b` before
  `cargo publish -p a`) — crates.io needs B already live before it will
  accept A's reference to it.
- crates.io requires `description` and `license` (SPDX identifier) or
  `license-file` in `Cargo.toml`, or the publish hard-fails. Also set
  `repository` and `readme = "README.md"` so the crates.io page links
  back and renders the README; add `keywords`/`categories` if relevant.
- Tag the repo at the exact commit you intend to publish, before any
  further changes — the GitHub Release's source archive and what
  `cargo publish` uploads should be the same tree.
- If publishing from CI, gate the publish job on the tag pattern (e.g.
  `v[0-9]+.*`) so it only runs on intentional release tags, not every
  push to main.
