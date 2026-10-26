{ pkgs, ... }:

{
  # Kept running like Non-Mixer-XT/qpwgraph rather than launched via the "m"
  # spawn key, so it's always up and ready. className =? "MIDI Staff Trainer"
  # in xmonad's manageHook pins its window to U14.
  systemd.user.services.midi-staff-trainer = {
    Unit = {
      Description = "MIDI Staff Trainer";
      # Not WantedBy anything -- only started via display-ready.target (see
      # its definition above). This app reads display geometry once at
      # startup and never re-checks it, so ordering alone (After=
      # autorandr.service) wasn't enough: it could still start against a
      # not-yet-corrected profile from the login race those commits fixed
      # (37b1528, 0c7d079), landing wrong until something else forced
      # XMonad to relayout it (e.g. switching desktops).
      After = [
        "graphical-session.target"
        "display-ready.target"
      ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.midi-staff-trainer}/bin/midi-staff-trainer";
      Restart = "always";
      RestartSec = 2;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
      TimeoutStopSec = 10;
    };
  };
}
