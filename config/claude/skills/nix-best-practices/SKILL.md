---
name: nix-best-practices
description: Use whenever creating, modifying, or evaluating a Nix flake, NixOS module, home-manager config, or any .nix file in this repo — and whenever preparing a change intended to be upstreamed to nixpkgs itself. Covers flake.lock hygiene, validating a NixOS config before switching to it, module-system priority (mkDefault/mkForce/mkMerge), linting/formatting, the git-tracked-files evaluation gotcha, overlay/callPackage correctness, and the nixpkgs contribution workflow (pkgs/by-name, commit conventions, meta attributes, nixpkgs-review). Triggers on "flake.nix", "flake.lock", "NixOS", "nixosConfigurations", "home-manager", ".nix", "nix flake check", "nixos-rebuild", "overlay", "callPackage", "nixpkgs", "pkgs/by-name", "nixpkgs-review", "upstream to nixpkgs".
---

# Nix and nixpkgs hygiene

This repo is a multi-host NixOS flake (`daw`, `fwork`, `tprice`, `eric`),
not a dev-shell project — the hygiene problems here are about safely
changing a system other people's uptime depends on, not about package
publishing to a registry. A separate set of conventions applies if
you're preparing a change to send upstream to nixpkgs itself; that's
covered at the end.

## flake.lock

- **Commit `flake.lock`.** It pins every input's exact revision — the
  same reproducibility role `Cargo.lock`/`uv.lock` play for their
  ecosystems. Without it, "the same flake" on two machines can
  silently resolve different nixpkgs revisions.
- Update one input at a time — `nix flake update <input>` — rather
  than a bare `nix flake update` (every input) unless you specifically
  want everything to move together. A single targeted bump is easy to
  review and easy to bisect if it breaks something; a wholesale update
  mixes dozens of unrelated upstream changes into one commit.
- Commit the lockfile diff in the same commit as whatever needed the
  bump (a module requiring a newer home-manager, a package only
  available after a nixpkgs bump) — same drift discipline as any other
  lock file.

## Validate before you deploy

- `nix flake check` evaluates every `nixosConfiguration` the flake
  defines, not just the host you're editing — run it after touching
  any shared module (`etc/nixos/configuration.nix`, anything under
  `config/modules`), since breaking one host via a shared module
  usually breaks all of them.
- Before `nixos-rebuild switch`, build first:
  `nixos-rebuild build --flake .#<host>` (or
  `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`).
  This evaluates and builds the full closure without touching the
  running system, so a mistake is caught before anything is activated.
- Diff the closure before switching —
  `nvd diff /run/current-system ./result` (or
  `nix store diff-closures /run/current-system ./result`) — to see
  exactly which packages and services would change. Reading this diff
  is the difference between an intentional rebuild and accidentally
  restarting every systemd unit because a shared dependency bumped.
- `switch` is the one step that mutates the running system and what
  you boot into next. For a disk-encrypted host (`daw`/`fwork`, via
  `config/disko/encrypted.nix`), a broken boot is a meaningfully more
  involved recovery than on a plainly-partitioned host — treat
  `switch` with proportionally more care there.

## Module system priority (mkDefault / mkForce / mkMerge)

- Use `lib.mkDefault` for a value a module sets as a sensible default
  that something more specific should be free to override — the way
  `musnix-audio.nix`'s `mkDefault` comments already treat
  `cpuFreqGovernor` relative to `power-profiles-daemon`. Reserve
  `lib.mkForce` for when you specifically need to win a priority
  conflict, like this flake's per-host `networking.hostName` and
  keyboard-layout overrides.
- Don't reach for `mkForce` reflexively just because a plain
  assignment conflicted with something else. Once one module forces a
  value, overriding it again anywhere else also needs `mkForce` (or a
  higher-priority `mkOverride`) — an `mkForce` answering an `mkForce`
  is an arms race. The actual fix is usually to lower the priority of
  whichever value shouldn't have been forced in the first place.
- `lib.mkMerge [ ... ]` combines a list of attribute sets using the
  module system's own merge semantics, so nested `mkIf`/`mkDefault`
  inside each still resolve correctly — reach for it instead of
  manually merging attrsets with `//` whenever any of the merged
  values carry their own priority.
- `lib.mkIf cond { ... }` over a plain `if cond then { ... } else { }`
  for conditional module config. `mkIf`'s branch is lazy and tags its
  priority correctly for the merge; a bare `if`/`else` evaluates both
  branches eagerly, which can trip a failing assertion that `mkIf`
  would have skipped entirely.

## Lint and format every touched file

- Run `nixfmt` on every `.nix` file you touch — this repo installs the
  official `nixfmt`, not a community alternative, so match its output
  rather than hand-formatting to look similar.
- Run `statix check` (anti-pattern linter: `with` shadowing,
  unreachable branches, redundant `rec`) and `deadnix` (unused `let`
  bindings and function arguments) before calling a change done — both
  are already installed in this repo's `home.nix` for exactly this.
- `nix flake check` only verifies evaluation succeeds; it catches
  neither style nor dead code. Treat it and the linters above as
  separate, both-required steps, not substitutes for each other.

## The git-tracked-files gotcha

- A flake backed by a local git checkout only evaluates **git-tracked
  files**. A new file sitting in the working tree but not yet
  `git add`ed is invisible to `nix flake check`/`nix build` and fails
  outright with "is not tracked by Git," not a silent skip.
- `git add` a new file before evaluating, even if you don't intend to
  commit yet — staging is enough, a commit isn't required. (This is
  not a hypothetical: adding the Python/Bash skill files to this same
  repo failed `nix flake check` until they were staged.)

## Overlays and `callPackage` correctness

- Name an overlay's arguments `final`/`prev` (or `self`/`super`),
  never a reused outer `pkgs`. `prev` is the package set *before* this
  overlay's changes; `final` is the package set *after all* overlays
  (including this one) are applied. Referencing the wrong one, or
  closing over an outer `pkgs` instead of using the arguments you were
  given, is how an overlay recurses into itself the moment it touches
  something it also depends on.
- Build a new package against `prev`, not `final`, unless you
  specifically need another overlay's changes visible to this one —
  e.g. this flake's overlay correctly does
  `prev.callPackage ./config/packages/midi-daemon.nix { }` for a
  brand-new package, since there's no reason for it to see any
  sibling overlay entry.
- `overrideAttrs` modifies one existing package's derivation — this
  flake's `system-config-printer` patch is the right use case: start
  from the existing derivation, change one thing. An overlay is for
  adding a new top-level attribute or systematically redirecting an
  existing one. Don't reach for a whole overlay entry to patch a
  single attribute when `pkg.overrideAttrs (old: { ... })` inline does
  the same thing with less indirection.

## Contributing to nixpkgs

A different repo, a different workflow — these apply once a package
or fix is meant to be upstreamed rather than kept local to this flake.

- New top-level packages go in
  `pkgs/by-name/<2-letter-prefix>/<package-name>/package.nix` (e.g.
  `pkgs/by-name/cs/csvargs/package.nix`), not `all-packages.nix` — this
  is the default path for anything built with plain `pkgs.callPackage`,
  and CI (`nixpkgs-vet`) enforces that the directory name matches the
  attribute name exactly. `all-packages.nix` is still correct when the
  package needs a non-default argument override (e.g. a different
  version of a dependency than the top-level attribute resolves to).
- Commit message format: `<attribute>: <change>`, no trailing period —
  `csvargs: init at 1.0.0` for a new package, `csvargs: 1.0.0 -> 1.1.0`
  for a version bump, `csvargs: fix build on darwin` for a fix. One
  logical change per commit; squash "oops, forgot a semicolon" fixups
  before opening the PR rather than leaving them as separate commits.
- Set `meta.license`, `meta.description` (no package name inside it,
  no trailing period, capitalized first letter), `meta.homepage`, and
  `meta.mainProgram` if the package installs exactly one executable
  under `$out/bin` — skip `mainProgram` if there are several and none
  is clearly "the" program.
- Adding yourself as a maintainer is a **separate commit** titled
  `maintainers: add <handle>`, placed before the commit that
  references you in `meta.maintainers`, editing
  `maintainers/maintainer-list.nix`.
- **Use `versionCheckHook` instead of hand-rolling a version check.**
  Add `nativeInstallCheckInputs = [ versionCheckHook ]; doInstallCheck
  = true;` and the hook runs the package's main program (by default
  with `--version`; override the flag with `versionCheckProgramArg =
  "--help";` if that's what actually prints a version) during every
  build, asserting `finalAttrs.version` shows up in the output. Don't
  write a `passthru.tests.foo = runCommand ... '' [[ "$output" == *
  ... ]] ''` block that does the same check by hand — a reviewer will
  ask why the standard hook wasn't used, and a hand-rolled
  `passthru.tests` attribute only runs when someone explicitly builds
  it, while the hook runs unconditionally as part of the package build
  itself.
- **Never duplicate the version string.** With the `finalAttrs:`
  pattern, every place that needs it — the fetcher's `tag`, a
  changelog URL, anything else — should reference `finalAttrs.version`
  (or `finalAttrs.src.tag` for a value that should track exactly what
  was fetched), never a second hand-typed copy of the version. A
  hardcoded duplicate is what goes stale the next version bump, when
  only the `version` field gets updated and the copy elsewhere doesn't.
- **Don't hand-roll submodule exclusion to save a little fetch size.**
  If you're tempted to fetch a dependency's submodules separately via
  their own `fetchFromGitHub` calls and splice them into place with
  `postUnpack`/`cp -r` just to skip one unwanted submodule, prefer
  patching `.gitmodules` (or simply eating the extra download) over
  reimplementing submodule resolution by hand — the manual version
  means re-deriving every pinned hash yourself on each upstream bump,
  for a download-size saving a reviewer will likely consider not worth
  the complexity.
- **De-duplicate a fetch shared by sibling packages.** If two packages
  in the same PR (or the same area of nixpkgs) fetch the identical
  source at the identical pinned revision, that's a signal to factor
  it into one place both consume rather than declaring the same
  `fetchFromGitHub { ... }` twice — two independent copies of the same
  pin will drift the moment only one of them gets bumped.
- Before opening the PR, build the package directly
  (`nix-build -A <name>`, since nixpkgs itself has no root
  `flake.nix` to `flake check`), then run
  `nixpkgs-review wip` (uncommitted changes) or
  `nixpkgs-review rev HEAD` (last commit) to build every package that
  depends on yours, not just the one you touched — this is what
  catches "the version bump broke three reverse dependencies" before
  a reviewer does. This repo already installs `nix-update` and
  `nixpkgs-reviewFull` for exactly this workflow.
- Use `nix-update <name> --version=<new>` to bump a package's version
  and source hash together rather than hand-editing both — a
  hand-edited hash that doesn't match the new source fails the build
  with an opaque hash-mismatch error instead of a clear diff.
- Base the PR branch on current `master` unless the change is part of
  a large, already-coordinated rebuild (those go through `staging`) —
  if in doubt, `master` is the default and a maintainer will redirect
  it if that's wrong.
