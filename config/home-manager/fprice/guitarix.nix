{ pkgs, ... }:

{
  # Moved from xmonad's startupHook (spawnOn "U11"): kept running like
  # Non-Mixer-XT/TouchOSC rather than a one-shot launch, since the amp sim
  # should always be up and ready. className =? "Guitarix" in xmonad's
  # manageHook pins its window to U11 the way doShift did before.
  systemd.user.services.guitarix = {
    Unit = {
      Description = "Guitarix amp simulator";
      # Not WantedBy anything -- only started via display-ready.target (see
      # its definition above), so its window doesn't map before the monitor
      # layout settles.
      After = [
        "graphical-session.target"
        "display-ready.target"
        "pipewire.service"
        "wireplumber.service"
      ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.guitarix-wrapped}/bin/guitarix";
      Restart = "always";
      RestartSec = 2;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
      TimeoutStopSec = 10;
    };
  };
}
