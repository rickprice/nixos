{ pkgs, ... }:

{
  systemd.user.services.xscreensaver = {
    Unit = {
      Description = "XScreensaver screen locker";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
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
      timeout:       0:10:00
      lock:          True
      lockTimeout:   0:05:00
      passwdTimeout: 0:00:30
      mode:          blank
      fade:          False
      unfade:        False
      dpmsEnabled:   True
      dpmsStandby:   0:30:00
      dpmsSuspend:   0:30:00
      dpmsOff:       0:30:00
    '';
  };
}
