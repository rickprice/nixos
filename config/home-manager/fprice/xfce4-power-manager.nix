{ pkgs, ... }:

{
  systemd.user.services.xfce4-power-manager = {
    Unit = {
      Description = "XFCE4 Power Manager";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.xfce4-power-manager}/bin/xfce4-power-manager";
      Restart = "on-failure";
      RestartSec = 1;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Write xfce4-power-manager config directly to avoid requiring xfconfd at activation time
  xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-power-manager" version="1.0">
      <property name="xfce4-power-manager" type="empty">
        <property name="power-button-action" type="uint" value="3"/>
      </property>
    </channel>
  '';
}
