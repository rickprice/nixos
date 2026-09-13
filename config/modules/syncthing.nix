# vim: set ts=2 sw=2 et:
# Syncthing is managed as a user service in home-manager/home.nix so it can
# depend on the rclone Dropbox FUSE mount. Only the firewall ports live here.
#
# Device IDs (configure peers via http://localhost:8384):
#   fwork:   FVU2BRC-3VW47AN-ZR44C24-RB6CFZW-BXAPPHS-NLFCFQY-OKITGEN-6EMWIQF
#   daw:     REPLACE-WITH-DAW-DEVICE-ID
#   android: SVKN2P3-74JHTNE-JY5XVLL-DGAXLM7-RZJYB5M-IC63VWP-32DNUJP-SQ2YNAC
{ ... }:

{
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };
}
