# vim: set ts=2 sw=2 et:
{ ... }:

{
  services.syncthing = {
    enable = true;
    user = "fprice";
    dataDir = "/home/fprice";
    configDir = "/home/fprice/.config/syncthing";
    # Folders and devices are configured via the web UI at http://localhost:8384
    # or can be added declaratively here later.
    settings.gui.insecureSkipHostcheck = false;
  };

  networking.firewall = {
    allowedTCPPorts = [ 22000 ];
    allowedUDPPorts = [ 22000 21027 ];
  };
}
