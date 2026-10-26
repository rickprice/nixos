{ pkgs, ... }:

{
  # Rclone Dropbox FUSE mount
  systemd.user.services.rclone-dropbox = {
    Unit = {
      Description = "Rclone Dropbox FUSE mount";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p /home/fprice/Documents/Personal/Dropbox";
      ExecStart = "${pkgs.rclone}/bin/rclone mount Dropbox: /home/fprice/Documents/Personal/Dropbox --vfs-cache-mode full --vfs-cache-max-size 500G --buffer-size 256M --vfs-read-ahead 512M --vfs-read-chunk-size 32M --vfs-read-chunk-size-limit 1G --dir-cache-time 1h --poll-interval 30s --transfers 8";
      ExecStop = "${pkgs.fuse3}/bin/fusermount3 -u /home/fprice/Documents/Personal/Dropbox";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 15;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
