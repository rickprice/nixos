{ pkgs, ... }:

{
  systemd.user.services.discord = {
    Unit = {
      Description = "Discord messaging client";
      After = [
        "graphical-session.target"
        "trayer.service"
      ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.discord}/bin/discord";
      Restart = "on-failure";
      RestartSec = 5;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
