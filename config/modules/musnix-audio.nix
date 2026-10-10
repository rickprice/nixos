{ ... }:
{
  musnix.enable = true;

  # musnix.kernel.realtime (PREEMPT_RT) is left at its default (false).
  # Swapping to an RT-patched kernel is a bigger, riskier change than the
  # rest of what musnix.enable already provides on top of this repo's
  # existing manual tuning (performance governor, @audio PAM limits,
  # vm.swappiness, security.rtkit.enable are all already set and match
  # musnix's own defaults) — namely the hpet/rtc0/cpu_dma_latency udev
  # rules this repo was missing. Revisit kernel.realtime if XRUNs persist
  # after this.
}
