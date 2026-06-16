{ config, lib, pkgs, ... }:

let
  cfg = config.services.midi-daemon;
in {
  options.services.midi-daemon = {
    enable = lib.mkEnableOption "midi-daemon, a Lua-scriptable MIDI routing daemon";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.midi-daemon;
      defaultText = lib.literalExpression "pkgs.midi-daemon";
      description = "The midi-daemon package to use.";
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression ''"/etc/midi-daemon/config.toml"'';
      description = ''
        Path to config.toml. When null the daemon falls back to its built-in
        search order (/etc/midi-daemon/config.toml then built-in defaults).
      '';
    };

    routesDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = lib.literalExpression ''"/etc/midi-daemon/routes.d"'';
      description = ''
        Path to the Lua routes directory. When null it is derived from the
        location of configFile (routes.d next to it).
      '';
    };

    logLevel = lib.mkOption {
      type = lib.types.enum [ "error" "warn" "info" "debug" ];
      default = "info";
      description = "Log verbosity (sets RUST_LOG=midi_daemon=LEVEL).";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "midi-daemon";
      description = "User account under which midi-daemon runs.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "midi-daemon";
      description = "Primary group for the midi-daemon user.";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "audio" ];
      description = "Extra groups for the midi-daemon user. Keep 'audio' for ALSA access.";
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.${cfg.user} = {
      isSystemUser = true;
      group        = cfg.group;
      extraGroups  = cfg.extraGroups;
      description  = "midi-daemon service user";
    };

    users.groups.${cfg.group} = {};

    systemd.services.midi-daemon = {
      description = "MIDI Lua Routing Daemon";
      wantedBy = [ "multi-user.target" ];
      after = [ "sound.target" "pipewire.service" "pipewire-pulse.service" ];

      serviceConfig = {
        Type          = "simple";
        ExecStart     =
          "${cfg.package}/bin/midi-daemon"
          + lib.optionalString (cfg.configFile != null) " --config ${cfg.configFile}"
          + lib.optionalString (cfg.routesDir  != null) " --routes ${cfg.routesDir}";
        ExecReload    = "${pkgs.coreutils}/bin/kill -USR1 $MAINPID";
        Restart       = "on-failure";
        RestartSec    = 2;
        User          = cfg.user;
        Group         = cfg.group;
        KillSignal    = "SIGTERM";
        TimeoutStopSec = 30;
        RuntimeDirectory = "midi-daemon";
        CacheDirectory   = "midi-daemon";
        StandardOutput = "journal";
        StandardError  = "journal";
        Environment    = "RUST_LOG=midi_daemon=${cfg.logLevel}";
      };
    };
  };
}
