---
name: touchosc
description: Use whenever reading, writing, building, or inspecting a TouchOSC (.tosc) layout file, or doing anything with TouchOSC/OSC/MIDI layouts generally. Triggers on ".tosc", "TouchOSC", "touch osc", "OSC layout", or a request to create/edit/inspect a TouchOSC page/group/button/fader/XY pad/encoder/pager/control. Do NOT hand-decompress, grep, or hand-edit .tosc XML directly, even for a "quick look" -- use this tool instead.
---

# TouchOSC layouts

`.tosc` files are zlib-compressed XML with a nontrivial internal
structure (typed properties, OSC/MIDI message bindings, embedded Lua
scripts, UUID-identified nodes). Hand-editing them — including "just
decompress it and grep" one-off scripts — is exactly how they get
silently corrupted. Use `touch-osc-utilities-rs` instead:

https://github.com/rickprice/touch-osc-utilities-rs

A Rust library (`touch-osc-core`) + CLI (`tosc`) built for this: a
lossless generic tree is the source of truth, typed builders/validation
sit on top of it and never drop data they don't understand.

## Get it

```sh
git clone git@github.com:rickprice/touch-osc-utilities-rs.git
cd touch-osc-utilities-rs
cargo build --release   # binary at target/release/tosc
# or: nix build          # binary at ./result/bin/tosc
```

If it's already cloned somewhere on this machine, use that checkout
(`git pull` first) instead of re-cloning.

## Workflow

- **Inspect a `.tosc` file**: `tosc dump <file.tosc>` — prints diffable
  YAML to stdout. Never decompress/parse the XML by hand.
- **Edit a layout**: `tosc dump file.tosc -o file.yaml`, edit the YAML,
  then `tosc build file.yaml -o file.tosc` (validates automatically;
  `--force` to build despite validation errors).
- **Validate without building**: `tosc validate <file.tosc>`.
- **Build a layout from scratch or programmatically**: use the
  `touch-osc-core` Rust library's typed builders (`controls::button`,
  `controls::fader`, `controls::pager`, `messages::osc_binding`, etc.) —
  see that repo's README for examples and `touch-osc-core/src/controls.rs`
  for the full set.
- **Lua scripts**: can be authored as separate `.lua` files and
  referenced from the YAML as `value: {file: path/to/script.lua}`;
  `tosc build` inlines them.

## If something's missing

If a feature isn't there yet (a new control type, a validation check, a
message shape), add it to `touch-osc-utilities-rs` first — following
that repo's own `CLAUDE.md` (read it before changing anything there) —
then use it. Don't work around a gap by dropping to raw XML.
