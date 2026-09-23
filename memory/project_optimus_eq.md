---
name: project-optimus-eq
description: EQ tuning history for Optimus PRO-X44AV speakers on fwork's USB 2.0 audio dongle
metadata:
  type: project
---

The Optimus PRO-X44AV (small ported bookshelf, 4" woofer) is connected via a USB 2.0 audio dongle on fwork. A PipeWire filter-chain EQ lives in `etc/nixos/configuration.nix` around line 235.

Current EQ values (no calibration mic — tuned by ear):
- HP  60 Hz Q=0.71  (cut inaudible sub-bass)
- +2 dB  80 Hz Q=1.5  (was +4 dB; reduced 2026-09-22 — sounded boomy)
- +4 dB 150 Hz Q=1.2  (was +5 dB; reduced 2026-09-22 — sounded boomy)
- +4 dB 250 Hz Q=1.0  (fullness)
- -1 dB 500 Hz Q=1.5  (reduce muddiness)
- -1 dB 3 kHz  Q=2.0  (tame presence harshness)
- -1 dB 8 kHz  Q=1.5  (soften treble)

**Why:** Original +4/+5 dB boosts in the 80–150 Hz range were excessive without a mic measurement to back them up.
**How to apply:** When further EQ tuning is requested, start from these current values, not the original ones. Note that a calibration mic (REW) would give more reliable numbers.
