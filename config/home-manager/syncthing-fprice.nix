{ pkgs, lib, ... }:

{
  home.packages = [ pkgs.syncthing ];

  services.syncthing = {
    enable = true;
    settings = {
      devices = {
        android.id = "SVKN2P3-74JHTNE-JY5XVLL-DGAXLM7-RZJYB5M-IC63VWP-32DNUJP-SQ2YNAC";
      };
      folders."MarkDownDocuments.personal" = {
        path = "/home/fprice/Documents/Personal/Dropbox/FrederickDocuments/MarkDownDocuments.personal";
        devices = [ "android" ];
      };
    };
  };

  # Wait for rclone-dropbox before starting; tie into graphical-session lifetime
  systemd.user.services.syncthing = {
    Unit = {
      After = lib.mkAfter [ "network-online.target" "rclone-dropbox.service" ];
      Wants = [ "network-online.target" "rclone-dropbox.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
  };
}
