{ pkgs, ... }:

{
  # Moved from xmonad's startupHook (spawnOn "U12"): kept running like
  # Non-Mixer-XT/TouchOSC rather than a one-shot launch, so the PipeWire
  # graph view is always available. className =? "qpwgraph" in xmonad's
  # manageHook pins its window to U12 the way doShift did before.
  systemd.user.services.qpwgraph = {
    Unit = {
      Description = "QPWGraph PipeWire patchbay";
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
      ExecStart = "${pkgs.qpwgraph}/bin/qpwgraph";
      Restart = "always";
      RestartSec = 2;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
      TimeoutStopSec = 10;
    };
  };
}
