{ pkgs, ... }:

{
  systemd.user.services = {
    # KWallet daemon — provides a secrets store for apps that use the KWallet API
    kwalletd6 = {
      Unit = {
        Description = "KWallet password manager daemon";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "dbus";
        BusName = "org.kde.kwalletd6";
        ExecStart = "${pkgs.kdePackages.kwallet}/bin/kwalletd6";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };

    # Unlock KWallet from the PAM token captured at SDDM login
    kwallet-pam-unlock = {
      Unit = {
        Description = "Unlock KWallet from PAM credentials";
        After = [ "kwalletd6.service" ];
        Requires = [ "kwalletd6.service" ];
        PartOf = [ "graphical-session.target" ];
      };
      Service = {
        Type = "oneshot";
        ExecStart = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
        RemainAfterExit = false;
      };
      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
