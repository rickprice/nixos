{ pkgs, ... }:

{
  # Wrap non-mixer-xt's, non-timeline-xt's, and new-session-manager's
  # binaries so they link against PipeWire's JACK library instead of the
  # real JACK, for the same reason Ardour/Carla/Guitarix are wrapped.
  # nmxt-patch doesn't talk to JACK directly, but is wrapped too for
  # consistency since it's cheap to do so. Of new-session-manager's
  # binaries, only jackpatch links against JACK directly.
  home.packages = [
    (pkgs.symlinkJoin {
      name = "non-mixer-xt";
      paths = [ pkgs.non-mixer-xt ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for bin in non-mixer-xt midi-mapper-xt nmxt-plugin-scan nmxt-patch; do
          wrapProgram $out/bin/$bin \
            --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
        done
      '';
    })
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
}
