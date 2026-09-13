# vim: set ts=2 sw=2 et:
{ config, ... }:

let
  # Fill these in after first boot on each machine:
  #   http://localhost:8384 → Actions → Show ID
  # or: sudo -u fprice syncthing cli config system status | grep myID
  dawDeviceId     = "REPLACE-WITH-DAW-DEVICE-ID";
  fworkDeviceId   = "FVU2BRC-3VW47AN-ZR44C24-RB6CFZW-BXAPPHS-NLFCFQY-OKITGEN-6EMWIQF";
  # On Android: Syncthing app → hamburger menu → Device ID
  androidDeviceId = "SVKN2P3-74JHTNE-JY5XVLL-DGAXLM7-RZJYB5M-IC63VWP-32DNUJP-SQ2YNAC";

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
      gui.apikey = "f9e96891-1e20-4b92-8303-a76c1931e990";
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
