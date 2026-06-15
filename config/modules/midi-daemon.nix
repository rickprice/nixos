{ config, lib, pkgs, ... }:

let
  cfg = config.services.midi-daemon;
  settingsFormat = pkgs.formats.toml {};
  # oscPort always wins for osc_receive_port so firewall and config stay in sync.
  effectiveSettings = cfg.settings //
    lib.optionalAttrs cfg.openFirewall { osc_receive_port = cfg.oscPort; };
in {
  options.services.midi-daemon = {
    enable = lib.mkEnableOption "midi-daemon Lua-scriptable MIDI routing daemon";

    openFirewall = lib.mkOption {
      type    = lib.types.bool;
      default = false;
      description = "Open the OSC receive port in the firewall (UDP) and write osc_receive_port to config.toml.";
    };

    oscPort = lib.mkOption {
      type    = lib.types.port;
      default = 9000;
      description = "UDP port for OSC input. Opened in the firewall and written to /etc/midi-daemon/config.toml when openFirewall = true.";
    };

    settings = lib.mkOption {
      type    = settingsFormat.type;
      default = {};
      description = "Global settings written to /etc/midi-daemon/config.toml. osc_receive_port is controlled by oscPort when openFirewall = true.";
      example = lib.literalExpression ''
        {
          default_bpm   = 120.0;
          osc_send_addr = "127.0.0.1:9001";
        }
      '';
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

    environment.etc."midi-daemon/config.toml".source =
      settingsFormat.generate "midi-daemon-config.toml" effectiveSettings;
  };
}
