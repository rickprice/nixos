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

  # The only folder this syncs lives under the Dropbox mount. Requires (not
  # just Wants) rclone-dropbox: if the mount fails, this must not start at
  # all — Wants alone would let syncthing start anyway against a real but
  # empty directory (ExecStartPre only mkdir's the Dropbox mountpoint
  # itself, so a failed mount leaves an empty tree underneath it, or
  # syncthing would just create the missing folder outright), and it would
  # propagate that as a mass delete to the paired Android device.
  systemd.user.services.syncthing = {
    Unit = {
      After = lib.mkAfter [ "network-online.target" "rclone-dropbox.service" ];
      Requires = [ "rclone-dropbox.service" ];
      Wants = [ "network-online.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = lib.mkForce [ "graphical-session.target" ];
  };
}
