{ pkgs, ... }:

{
  # Moved from xmonad's startupHook (spawnOn "ADM"): kept running rather than
  # a one-shot launch, so the vault is always open. className =? "Obsidian"
  # in xmonad's manageHook pins its window to ADM the way doShift did before.
  systemd.user.services.obsidian = {
    Unit = {
      Description = "Obsidian markdown editor";
      # Not WantedBy anything -- only started via display-ready.target (see
      # its definition above), so its window doesn't map before the monitor
      # layout settles.
      # The vault lives on the Dropbox FUSE mount (see obsidian.json); same
      # reasoning as non-mixer-xt's rclone-dropbox.service dependency --
      # without it Obsidian can start against a not-yet-mounted vault path
      # and map a degraded window that doShift then pins to ADM.
      After = [
        "graphical-session.target"
        "display-ready.target"
        "rclone-dropbox.service"
      ];
      Requires = [ "rclone-dropbox.service" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.obsidian}/bin/obsidian";
      Restart = "always";
      RestartSec = 2;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
      TimeoutStopSec = 10;
    };
  };
}
