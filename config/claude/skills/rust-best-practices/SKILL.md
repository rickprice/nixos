---
name: rust-best-practices
description: Use whenever creating, modifying, or releasing a Rust crate or workspace (a Cargo.toml is present or about to be created). Covers keeping Cargo.lock and the README in sync with the code, benchmarking/profiling before optimizing, and making GitHub releases line up cleanly with crates.io publishing. Triggers on "cargo", "crate", "Cargo.toml", "Rust project", "cut a release", "publish to crates.io", "GitHub release", "benchmark", "criterion", "profile", "flamegraph", "optimize Rust".
---

# Rust project hygiene

Four things repeatedly go stale or get botched in Rust projects if
nobody enforces them deliberately. Check all four whenever you touch a
Rust crate's dependencies, public surface, performance-sensitive code,
or cut a release.

## Cargo.lock

- **Commit `Cargo.lock`** — for binaries and libraries alike. The Rust
  team's older binary-only guidance was relaxed in 2023: the current
  recommendation is "do what's best for your project," and committing
  is the reasonable default either way. It's the only thing that makes
  CI, `cargo install --locked`, and Nix builds (`buildRustPackage` with
  `cargoLock.lockFile`) reproducible, and it means a new contributor or
  CI run gets the exact dependency tree you tested against instead of
  whatever resolves at that moment. Don't gitignore it.
- Whenever you add, remove, or bump a dependency in `Cargo.toml`, run
  `cargo build` (or `cargo update -p <pkg>`) and commit the resulting
  `Cargo.lock` diff **in the same commit** as the `Cargo.toml` change —
  never let them drift apart across commits.
- Build with `--locked` in CI and release builds (`cargo build --release
  --locked`) so a drifted lockfile fails loudly instead of silently
  resolving different versions than what's committed.
- Never hand-edit `Cargo.lock`.
- `cargo audit` checks `Cargo.lock` against the RustSec advisory
  database — worth running before a release, and in CI if the project
  has any exposure (network-facing, parses untrusted input, etc.).

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

## Performance

- Don't optimize blind. Profile first — `cargo flamegraph` (wraps
  `perf` on Linux) or `samply` — on a `--release` build, since debug
  builds are 10-100x slower and have different hot spots entirely.
  Fix what the profile actually shows, not what looks slow on
  inspection; intuition about hot paths is wrong more often than not.
- Benchmark with `criterion`, not `Instant::now()` wrapped around a
  loop in `main`. Criterion's warmup phase accounts for one-off
  JIT/cache effects, runs enough iterations to average out noise, and
  will tell you outright when a result isn't statistically
  distinguishable from the baseline — a hand-rolled timer loop does
  none of that, so a single run from one risks being pure noise.
- Treat a `cargo bench` regression like a test failure: investigate
  before merging, not after. `cargo bench -- --save-baseline main` on
  the base branch, then `--baseline main` on the PR branch, gives a
  direct before/after comparison instead of eyeballing two separate
  runs.
- Avoid unnecessary allocation in hot paths: `Cow<str>` for a function
  that sometimes borrows and sometimes needs to allocate; `&str`/`&[T]`
  parameters instead of `String`/`Vec<T>` when the callee doesn't need
  ownership; `Vec::with_capacity`/`.extend(...)` instead of a `push`
  loop that reallocates repeatedly.
- Prefer `Arc::clone(&x)` over `x.clone()` for a shared pointer. Both
  do the same refcount bump, but the explicit form makes it obvious at
  the call site that this isn't a deep copy — a bare `.clone()` on an
  `Arc<BigStruct>` reads identically to cloning `BigStruct` itself
  until you check the type.
- Don't reach for `unsafe` to "make it fast" before a profile says
  bounds-checking/allocation/etc. is the actual bottleneck — the
  maintenance cost of unsafe code outlives whatever performance
  problem it solved. If a flamegraph does point squarely at one of
  those, check for an existing safe fast path first (`SmallVec` to
  avoid heap allocation for small collections, `itertools` adaptors
  that fuse iterator passes) before writing new unsafe code.

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
- Prefer **Trusted Publishing (OIDC)** over a long-lived
  `CARGO_REGISTRY_TOKEN` secret when publishing from GitHub Actions or
  GitLab CI. Configure the trusted publisher on the crates.io crate
  settings page (repo + workflow filename), give the publish job
  `permissions: id-token: write`, and exchange the token via
  `rust-lang/crates-io-auth-action` immediately before `cargo publish`.
  The exchanged token is scoped to that one crate and expires in 30
  minutes, so there's no standing secret to leak or rotate. Keep the
  publish step in its own job gated by the tag pattern above, separate
  from build/test, since it's the one step that needs the elevated
  `id-token` permission.
