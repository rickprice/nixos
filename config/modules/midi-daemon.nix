{ config, lib, pkgs, ... }:

let
  cfg = config.services.midi-daemon;
in {
  options.services.midi-daemon = {
    enable = lib.mkEnableOption "midi-daemon Lua-scriptable MIDI routing daemon";

    openFirewall = lib.mkOption {
      type    = lib.types.bool;
      default = false;
      description = "Open the OSC receive port in the firewall (UDP).";
    };

    oscPort = lib.mkOption {
      type    = lib.types.port;
      default = 9000;
      description = "UDP port to open when openFirewall is true. Must match osc_receive_port in config.toml.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.packages = [ pkgs.midi-daemon ];
    systemd.services.midi-daemon.wantedBy = [ "multi-user.target" ];

    users.users.midi-daemon = {
      isSystemUser = true;
      group        = "midi-daemon";
      extraGroups  = [ "audio" ];
      description  = "MIDI Lua Routing Daemon";
    };
    users.groups.midi-daemon = {};

    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ cfg.oscPort ];
  };
}
