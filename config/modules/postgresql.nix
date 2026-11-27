# vim: set ts=2 sw=2 et:
{ pkgs, ... }:
{
  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    # Unix socket only, no TCP listener: a local dev web app connects over
    # the socket with peer auth, so there's nothing to open in the firewall
    # and no network-facing attack surface.
    enableTCPIP = false;
  };

  # fwork runs a PREEMPT_RT audio kernel (musnix-audio.nix). RT threads
  # always preempt plain SCHED_OTHER processes like postgres regardless of
  # cgroup weight, so it can't cause audio dropouts by stealing the CPU core
  # a JACK/pipewire RT thread is running on. The real risk is everything
  # else on the system: a bursty query or autovacuum run competing with the
  # DAW's non-RT work (GUI, plugin UI, disk I/O while recording). Capping
  # memory and deprioritizing CPU/IO keeps it from ever being the thing that
  # makes a session feel sluggish.
  systemd.services.postgresql.serviceConfig = {
    MemoryHigh = "512M";
    MemoryMax = "1G";
    CPUWeight = 10;
    IOWeight = 10;
  };
}
