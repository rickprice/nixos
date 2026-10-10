{ pkgs, ... }:
{
  musnix.enable = true;

  # PREEMPT_RT, via musnix's "native RT" path: our kernel (linuxPackages_latest,
  # well above the 6.12 cutoff) gets PREEMPT_RT enabled through a structured
  # config override and rebuilt from source — no separately RT-patched kernel
  # package needed. This no longer builds from the binary cache, and every
  # out-of-tree kernel module rebuilds against the new kernel ABI, so expect
  # a long first build. No NVIDIA driver, no ZFS, and no other known hardware
  # incompatibility was found on daw/fwork for this.
  musnix.kernel.realtime = true;
  musnix.kernel.packages = pkgs.linuxPackages_latest;
}
