{ pkgs, osConfig, ... }:

let
  nonMixerXtWrapped = pkgs.symlinkJoin {
    name = "non-mixer-xt";
    paths = [ pkgs.non-mixer-xt ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in non-mixer-xt midi-mapper-xt nmxt-plugin-scan nmxt-patch; do
        wrapProgram $out/bin/$bin \
          --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
      done
    '';
  };

  # Kept under the NixOS config repo (not ~/Documents/Personal/NonMixerProjects)
  # so it's tracked alongside the service that launches it. Non-Mixer-XT
  # rewrites files in here (lock, snapshot, plugin state) every session, so
  # expect this path to show up dirty in `git status` after normal use.
  keyboardAndGuitarixProject =
    "/home/fprice/Documents/Personal/personal_repo/nixos/config/non-mixer-xt/KeyboardAndGuitarix";
in {
  # Wrap non-mixer-xt's, non-timeline-xt's, and new-session-manager's
  # binaries so they link against PipeWire's JACK library instead of the
  # real JACK, for the same reason Ardour/Carla/Guitarix are wrapped.
  # nmxt-patch doesn't talk to JACK directly, but is wrapped too for
  # consistency since it's cheap to do so. Of new-session-manager's
  # binaries, only jackpatch links against JACK directly.
  home.packages = [
    nonMixerXtWrapped
    (pkgs.symlinkJoin {
      name = "non-timeline-xt";
      paths = [ pkgs.non-timeline-xt ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/non-timeline-xt \
          --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
      '';
    })
    (pkgs.symlinkJoin {
      name = "new-session-manager";
      paths = [ pkgs.new-session-manager ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/jackpatch \
          --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
      '';
    })
    pkgs.midi-auto-connector
  ];

  # Routes the A-PRO controller and the midi-daemon-driven Metronome into
  # Non-Mixer-XT's sfizz Control ports, and fans Non-Mixer-XT's per-strip
  # audio outputs (and its own Mains bus) into the UMC404HD interface.
  # See https://github.com/rickprice/midi-auto-connector for the config
  # format; `midi-auto-connector list-ports` shows the live port names
  # these regexes match against.
  xdg.configFile."midi-auto-connector/config.toml".text = ''
    [backends]
    alsa = true
    pipewire = true

    [lua]
    timeout_ms = 500

    [[rule]]
    name = "a-pro-to-sfizz"
    backend = "pipewire"
    output = '^Midi-Bridge:A-PRO: 1 \(capture\)$'
    input = "^Non-Mixer-XT/Piano:sfizz Control$"

    [[rule]]
    name = "metronome-to-sfizz"
    backend = "pipewire"
    output = '^Midi-Bridge:midi-daemon:Metronome/midi-out:midi-daemon:Metronome/midi \(capture\)$'
    input = "^Non-Mixer-XT/Metronome:sfizz Control$"

    [[rule]]
    name = "mains-out1-to-umc404hd-fl"
    backend = "pipewire"
    kind = "audio"
    output = '^Non-Mixer-XT/Mains:out-1$'
    input = '^umc404hd_combined:playback_FL$'

    [[rule]]
    name = "mains-out2-to-umc404hd-fr"
    backend = "pipewire"
    kind = "audio"
    output = '^Non-Mixer-XT/Mains:out-2$'
    input = '^umc404hd_combined:playback_FR$'

    [[rule]]
    name = "non-mixer-to-mains"
    backend = "pipewire"
    kind = "audio"
    output = '^Non-Mixer-XT/(?:Metronome|Piano|Vocals|Guitar):out-(\d+)$'
    input = '^Non-Mixer-XT/Mains:in-(\d+)$'

    [[rule]]
    name = "gx-head-fx-to-guitar-l"
    backend = "pipewire"
    kind = "audio"
    output = '^gx_head_fx:out_0$'
    input = '^Non-Mixer-XT/Guitar:in-1$'

    [[rule]]
    name = "gx-head-fx-to-guitar-r"
    backend = "pipewire"
    kind = "audio"
    output = '^gx_head_fx:out_1$'
    input = '^Non-Mixer-XT/Guitar:in-2$'

    [[rule]]
    name = "umc404hd-aux0-to-vocals"
    backend = "pipewire"
    kind = "audio"
    output = '^alsa_input\.usb-BEHRINGER_UMC404HD_192k-00\.capture\.0\.0:capture_AUX0$'
    input = '^Non-Mixer-XT/Vocals:in-1$'
  '';

  systemd.user.services.midi-auto-connector = {
    Unit = {
      Description = "Auto-connects Non-Mixer-XT's MIDI/audio ports by regex rule";
      After = [ "graphical-session.target" "pipewire.service" "wireplumber.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.midi-auto-connector}/bin/midi-auto-connector run";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.non-mixer-xt = {
    Unit = {
      Description = "Non-Mixer-XT (KeyboardAndGuitarix project)";
      # The project's sfizz plugins load sample sets from the Dropbox FUSE
      # mount; rclone-dropbox is Type=notify, so After=/Requires= here
      # actually blocks until the mount is ready, not just until rclone has
      # been forked.
      After = [ "graphical-session.target" "pipewire.service" "wireplumber.service" "rclone-dropbox.service" ];
      Requires = [ "rclone-dropbox.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      # systemd --user units don't inherit the login shell's environment, so
      # NixOS's environment.variables (LV2_PATH/LADSPA_PATH/VST3_PATH) never
      # reach this unit on their own — without these, non-mixer-xt finds no
      # plugins at all.
      Environment = [
        "LV2_PATH=${osConfig.environment.variables.LV2_PATH}"
        "LADSPA_PATH=${osConfig.environment.variables.LADSPA_PATH}"
        "VST3_PATH=${osConfig.environment.variables.VST3_PATH}"
      ];
      ExecStart = "${nonMixerXtWrapped}/bin/non-mixer-xt --osc-port 9500 ${keyboardAndGuitarixProject}";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Moved from a NixOS system service to here: midi-daemon routes Non-Mixer-XT
  # OSC traffic, so it needs to start after non-mixer-xt exists, and systemd's
  # system and user managers can't order units against each other.
  systemd.user.services.midi-daemon = {
    Unit = {
      Description = "MIDI Lua Routing Daemon";
      After = [ "graphical-session.target" "non-mixer-xt.service" "pipewire.service" "wireplumber.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.midi-daemon}/bin/midi-daemon --config /etc/midi-daemon/config.toml --routes /etc/midi-daemon/routes.d";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 30;
      RuntimeDirectory = "midi-daemon";
      CacheDirectory = "midi-daemon";
      Environment = "RUST_LOG=midi_daemon=info";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Moved from xmonad's startupHook: previously spawned on login via spawnOn
  # "U13", now started as a user service (like non-mixer-xt/midi-daemon)
  # and pinned to U13 by WM_CLASS in xmonad's manageHook instead.
  systemd.user.services.touchosc = {
    Unit = {
      Description = "TouchOSC (ComplexSetup project)";
      After = [ "graphical-session.target" "midi-daemon.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.touchosc}/bin/TouchOSC --general.ui.editor=false --general.ui.fullscreen=true /home/fprice/.config/touchosc/ComplexSetup.tosc";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
