{ pkgs, config, ... }:

{
  systemd.user.services.xscreensaver = {
    Unit = {
      Description = "XScreensaver screen locker";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
      # xscreensaver only re-reads ~/.xscreensaver on an explicit
      # `xscreensaver-command -restart` (or SIGHUP), not automatically -- and
      # that file is home.file's Nix-store symlink below, retargeted on
      # every rebuild. Same issue as midi-daemon's X-Restart-Triggers: this
      # already-running process never notices, so without this trigger a
      # timeout/lock setting change silently has no effect until a manual
      # restart.
      "X-Restart-Triggers" = [ config.home.file.".xscreensaver".source ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.xscreensaver}/bin/xscreensaver --no-splash";
      Restart = "on-failure";
      RestartSec = 1;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.file.".xscreensaver" = {
    force = true;
    text = ''
      timeout:       1:00:00
      lock:          True
      lockTimeout:   0:01:00
      passwdTimeout: 0:00:30
      mode:          blank
      fade:          False
      unfade:        False
      dpmsEnabled:   True
      dpmsStandby:   1:00:00
      dpmsSuspend:   1:00:00
      dpmsOff:       1:00:00
    '';
  };
}
