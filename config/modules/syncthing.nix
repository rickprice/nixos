# vim: set ts=2 sw=2 et:
{ config, ... }:

let
  # Fill these in after first boot on each machine:
  #   http://localhost:8384 → Actions → Show ID
  # or: sudo -u fprice syncthing cli config system status | grep myID
  dawDeviceId     = "REPLACE-WITH-DAW-DEVICE-ID";
  fworkDeviceId   = "REPLACE-WITH-FWORK-DEVICE-ID";
  # On Android: Syncthing app → hamburger menu → Device ID
  androidDeviceId = "REPLACE-WITH-ANDROID-DEVICE-ID";

  isDAW        = config.networking.hostName == "daw";
  otherName    = if isDAW then "fwork"          else "daw";
  otherID      = if isDAW then fworkDeviceId    else dawDeviceId;
in
{
  services.syncthing = {
    enable = true;
    user = "fprice";
    dataDir = "/home/fprice";
    configDir = "/home/fprice/.config/syncthing";
    settings = {
      gui.insecureSkipHostcheck = false;
      devices.${otherName}  = { id = otherID; };
      devices."android"     = { id = androidDeviceId; };
      folders."MarkDownDocuments.personal" = {
        path = "/home/fprice/Documents/Personal/Dropbox/FrederickDocuments/MarkDownDocuments.personal";
        devices = [ otherName "android" ];
      };
    };
  };

  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };
}
