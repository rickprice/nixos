{ pkgs, ... }:

{
  systemd.user.services = {
    trayer = {
      Unit = {
        Description = "Trayer system tray";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.trayer}/bin/trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true --tint 0x000000 --height 22 --monitor primary";
        Restart = "on-failure";
        RestartSec = 1;
        RestartSteps = 4;
        RestartMaxDelaySec = "32s";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    nm-applet = {
      Unit = {
        Description = "NetworkManager tray applet";
        After = [
          "graphical-session.target"
          "trayer.service"
          "dunst.service"
        ];
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
        Restart = "on-failure";
        RestartSec = 2;
        RestartSteps = 4;
        RestartMaxDelaySec = "32s";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    pasystray = {
      Unit = {
        Description = "PulseAudio system tray";
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
        ExecStart = "${pkgs.pasystray}/bin/pasystray";
        Restart = "on-failure";
        RestartSec = 2;
        RestartSteps = 4;
        RestartMaxDelaySec = "32s";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    udiskie = {
      Unit = {
        Description = "Udiskie automount tray";
        After = [
          "graphical-session.target"
          "trayer.service"
          "dunst.service"
        ];
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.udiskie}/bin/udiskie --tray";
        Restart = "on-failure";
        RestartSec = 2;
        RestartSteps = 4;
        RestartMaxDelaySec = "32s";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    blueman-applet = {
      Unit = {
        Description = "Blueman Bluetooth manager applet";
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
        ExecStart = "${pkgs.blueman}/bin/blueman-applet";
        Restart = "on-failure";
        RestartSec = 5;
        RestartSteps = 4;
        RestartMaxDelaySec = "32s";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    system-config-printer-applet = {
      Unit = {
        Description = "system-config-printer tray applet";
        After = [
          "graphical-session.target"
          "trayer.service"
          "dunst.service"
        ];
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.system-config-printer}/bin/system-config-printer-applet";
        Restart = "on-failure";
        RestartSec = 5;
        RestartSteps = 4;
        RestartMaxDelaySec = "32s";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    polkit-gnome-authentication-agent-1 = {
      Unit = {
        Description = "polkit-gnome-authentication-agent-1";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
      Service = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        RestartSteps = 4;
        RestartMaxDelaySec = "32s";
        TimeoutStopSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
