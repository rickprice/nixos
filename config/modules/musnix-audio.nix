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

  # musnix.rtirq.enable defaults to false even with kernel.realtime on, so
  # it needs setting explicitly. This is the piece most directly aimed at
  # the UMC404HD XRUNs: it reprioritizes IRQ threads against the RT
  # scheduler, and its default nameList ("snd usb i8042") is specifically
  # the sound/USB/keyboard-controller interrupts. das_watchdog is already
  # on automatically (its default tracks kernel.realtime).
  musnix.rtirq.enable = true;
}
