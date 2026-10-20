---
name: bash-best-practices
description: Use whenever creating or modifying a Bash or ZSH script, or any shell snippet meant to be reused (not a one-off interactive command) — including a script that will be packaged as a Nix derivation. Covers strict mode, quoting, ShellCheck, the gap ShellCheck leaves for ZSH-specific scripts, and PATH pitfalls once a script runs under writeShellApplication/systemd instead of an interactive shell. Triggers on ".sh", ".zsh", "#!/bin/bash", "#!/usr/bin/env bash", "#!/usr/bin/env zsh", "shell script", "bash script", "zsh script", "writeShellApplication", "writeShellScriptBin".
---

# Shell script hygiene

Unlike Rust/Python, shell scripts have no package registry or lock
file to go stale — what actually breaks them is silent failure (a
command fails and the script keeps going anyway) and environment
sensitivity (works in your shell, breaks under `sh` or someone else's
`$IFS`). Check these whenever you write or touch a script meant to be
run more than once.

## Strict mode

- Start every script with:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```
  `-e` exits on any command's non-zero status, `-u` turns unset-variable
  use into an error instead of silently expanding to empty, `-o
  pipefail` makes a pipeline fail if *any* stage fails, not just the
  last one. Without `pipefail`, `cmd_that_fails | grep foo` reports
  success as long as `grep` itself didn't error.
- Know the gaps instead of trusting strict mode blindly: `set -e` does
  **not** fire inside an `if cmd; then` / `while cmd; do` condition, nor
  on the left side of `&&`/`||` — those contexts are expected to
  "fail" sometimes. For a command that's allowed to fail elsewhere, be
  explicit (`cmd || true`) rather than leaving it ambiguous whether the
  omission was intentional.
- Prefer `#!/usr/bin/env bash` over a hardcoded `#!/bin/bash` unless you
  specifically need the system path (e.g. a script that must survive a
  minimal/initrd environment) — it finds `bash` via `$PATH`, which
  matters on systems (including Nix-built environments) where `bash`
  isn't at `/bin/bash`.

## Quoting and footguns

- Quote every variable expansion and command substitution by default —
  `"$var"`, `"$(cmd)"` — unless you specifically want word-splitting
  and glob expansion (rare, and worth a comment when intentional).
  Unquoted expansions are the single most common source of a script
  working on your machine and breaking on a path with a space in it.
- Use `[[ ... ]]` for conditionals, not `[ ... ]` — it doesn't
  word-split or glob its operands, so `[[ -z "$var" ]]` is safe even if
  `$var` is unset-but-allowed or contains spaces.
- Use arrays for lists of arguments (`args=(--foo "$bar"); cmd "${args[@]}"`),
  never a single string you hope splits correctly — `"${args[@]}"`
  (quoted, with `@`) is the only form that preserves element
  boundaries.
- Don't parse `ls` output. Use globs, `find ... -print0 | while read -r -d ''`,
  or arrays instead — filenames can contain anything except `/` and
  `NUL`, including newlines and leading dashes, which breaks naive
  line-based parsing.
- Use `mktemp` for temp files/dirs, and `trap 'rm -rf "$tmpdir"' EXIT`
  to guarantee cleanup even if the script exits early via `set -e`.
- Prefix function-local variables with `local` (bash) so a helper
  function can't clobber a caller's variable of the same name.

## ShellCheck — and where it stops

- Run `shellcheck` on every Bash script before considering it done, and
  fix what it flags rather than reflexively disabling the check. If a
  specific warning genuinely doesn't apply, disable just that one
  (`# shellcheck disable=SC2034`) with a comment saying why, scoped as
  narrowly as possible (one line, not the whole file).
- **ShellCheck does not understand ZSH.** It only parses `sh`/`bash`/`dash`/
  `ksh` syntax (`shellcheck -s bash`) — pointing it at a `.zsh` file
  either misparses ZSH-specific syntax or silently skips real bugs.
  There is no equivalent static analyzer for ZSH in common use. For a
  ZSH script, the practical fallback is `zsh -n script.zsh` (parses
  without executing — catches syntax errors, nothing else) plus extra
  manual care around the differences below.
- If a piece of shell logic needs real static checking and doesn't
  depend on ZSH-only features (named parameters like `$reply`, glob
  qualifiers like `(.)`, `zsh/` module builtins), write it to run under
  `bash` instead so ShellCheck can actually cover it, even if it's
  invoked from an otherwise-ZSH environment (e.g. as a separate
  `#!/usr/bin/env bash` script ZSH calls out to).

## ZSH-specific traps

Don't assume ZSH is "bash with a different prompt" — these differences
cause real bugs when bash habits carry over:

- Arrays are **1-indexed** in ZSH (`arr[1]` is the first element), vs
  0-indexed in bash. Code ported between the two silently reads the
  wrong element rather than erroring.
- Unquoted variable expansion does **not** word-split by default in
  ZSH (`setopt` controls this, and the default is off) — the opposite
  of bash's default. A bash habit of relying on unquoted splitting
  breaks in ZSH; quoting everything (as recommended above regardless)
  sidesteps the difference entirely.
- `set -e`/`set -u`/`set -o pipefail` all work the same in ZSH, so
  strict mode transfers directly — but `[[ ]]` has a few ZSH-only
  extensions (e.g. `=~` regex matching differences), so don't assume a
  `[[ ]]` conditional is 100% portable between the two without checking.

## Nix packaging

When a script becomes a Nix derivation (`writeShellApplication`,
`writeShellScriptBin`, or wrapped in a package like this repo's
`config/packages/*.nix`), its runtime environment stops being your
interactive shell:

- Don't call a bare command name (`jq`, `curl`, `ffmpeg`, ...) and
  rely on `$PATH` to find it. Nothing guarantees the derivation's
  runtime `$PATH` contains what your login shell's does — a script
  that works fine run by hand can fail, or silently resolve to the
  wrong binary, once it's packaged.
- Prefer `writeShellApplication`'s `runtimeInputs` list over manual
  `$PATH` wiring — it prepends exactly the packages you list to
  `$PATH` for that script, and it runs the whole script through
  ShellCheck as part of the build, so a ShellCheck failure becomes a
  build failure instead of a runtime surprise. For a single binary
  reference without pulling in a whole wrapper, substitute the exact
  store path instead: `"${pkgs.jq}/bin/jq"` (or `${lib.getExe pkgs.jq}`)
  interpolated into the script at Nix eval time.
- This matters doubly for systemd units (`systemd.services.*`/
  `systemd.user.services.*`) — `ExecStart` runs with none of the
  environment a login shell sets up (no `.bashrc`/`.zshrc`, no
  `profile.d` PATH extensions), so a script relying on ambient `$PATH`
  can behave correctly when tested by hand and fail silently as a
  service.
