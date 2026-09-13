# vim: set ts=2 sw=2 et:
# Syncthing is managed via services.syncthing in home-manager/home.nix so it
# can depend on the rclone Dropbox FUSE mount. Only firewall ports live here.
#
# Device IDs (for reference — declaratively set in home.nix):
#   fwork:   6F6T2XV-QJMSBQP-5HHVWID-WOYQN7F-TA7MZKP-GF5ANAU-GP4TAKB-AWYQRAK
#   android: SVKN2P3-74JHTNE-JY5XVLL-DGAXLM7-RZJYB5M-IC63VWP-32DNUJP-SQ2YNAC
{ ... }:

{
  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };
}
