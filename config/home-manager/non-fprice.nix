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
  # TONE3000's Standalone app owns its own JACK device directly (same
  # reasoning as non-mixer-xt/non-timeline-xt below): point it at
  # PipeWire's JACK so it shares the UMC404HD instead of grabbing it
  # exclusively. The LV2/VST3/CLAP plugin formats don't need this -- they
  # run inside Non-Mixer-XT/Carla's own process, which is already wrapped.
  tone3000Wrapped = pkgs.symlinkJoin {
    name = "tone3000-plugin";
    paths = [ pkgs.tone3000-plugin ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/TONE3000 \
        --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
    '';
  };
in {
  # Wrap non-mixer-xt's, non-timeline-xt's, and new-session-manager's
  # binaries so they link against PipeWire's JACK library instead of the
  # real JACK, for the same reason Ardour/Carla/Guitarix are wrapped.
  # nmxt-patch doesn't talk to JACK directly, but is wrapped too for
  # consistency since it's cheap to do so. Of new-session-manager's
  # binaries, only jackpatch links against JACK directly.
  home.packages = [
    nonMixerXtWrapped
    tone3000Wrapped
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
    pkgs.usbutils  # lsusb

    # Lint/format tools for scripts and Rust bits written on this machine --
    # kept off tprice/eric since that's not where this kind of dev work happens.
    #
    # Standalone top-level packages, not python3.withPackages: this module
    # and home.nix both run on daw/fwork for the fprice user, and home.nix
    # already has its own python3.withPackages (ipython/requests/httpx/rich).
    # Two separate python3.withPackages envs can't coexist in home.packages
    # -- buildEnv fails with "conflicting subpath" the moment both try to
    # provide bin/pydoc, bin/python3, etc. from the wrapped interpreter.
    # Standalone packages like these only expose their own entry points, so
    # they don't collide with another python env the way a second
    # withPackages call would.
    pkgs.shellcheck # Bash linter (no equivalent zsh checker exists in nixpkgs)
    pkgs.rustfmt
    pkgs.clippy
    pkgs.black  # Python formatter
    pkgs.mypy   # Python type checker
    pkgs.pylint # Python linter
    pkgs.ruff   # Python PEP8/style checker -- flake8 isn't packaged top-level
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

  # Restart policy shared by the MIDI/audio service mesh below
  # (midi-auto-connector, non-mixer-xt, midi-daemon, touchosc): "always"
  # rather than "on-failure" because these are long-running GUI/daemon
  # processes that should come back even if they exit 0 (e.g. a GUI closed
  # by a stray Alt-F4 or a crash that happens not to set a nonzero exit
  # code) -- "on-failure" would silently leave them dead in that case.
  # RestartSteps/RestartMaxDelaySec back off exponentially (2s, 4s, 8s,
  # 16s, 32s, then holds at 32s) instead of hammering a genuinely broken
  # process every 2 seconds forever. StartLimitIntervalSec/StartLimitBurst
  # is the hard circuit breaker on top: 5 restarts inside 60s and systemd
  # gives up, leaving the unit "failed" instead of looping indefinitely --
  # `systemctl --user status <name>` will show that state, and
  # `systemctl --user reset-failed <name> && systemctl --user start <name>`
  # clears it once the underlying problem (missing device, bad project
  # file, etc.) is fixed. An explicit `systemctl --user stop` is never
  # overridden by any of this -- systemd always honors a manual stop.
  systemd.user.services.midi-auto-connector = {
    Unit = {
      Description = "Auto-connects Non-Mixer-XT's MIDI/audio ports by regex rule";
      After = [ "graphical-session.target" "pipewire.service" "wireplumber.service" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.midi-auto-connector}/bin/midi-auto-connector run";
      Restart = "always";
      RestartSec = 2;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
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
      # Not WantedBy anything -- only started via display-ready.target (see
      # home.nix) so its window doesn't map before the monitor layout
      # settles.
      After = [
        "graphical-session.target"
        "display-ready.target"
        "pipewire.service"
        "wireplumber.service"
        "rclone-dropbox.service"
      ];
      Requires = [ "rclone-dropbox.service" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
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
      Restart = "always";
      RestartSec = 2;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
      TimeoutStopSec = 10;
    };
  };

  # Moved from a NixOS system service to here: midi-daemon routes Non-Mixer-XT
  # OSC traffic, so it needs to start after non-mixer-xt exists, and systemd's
  # system and user managers can't order units against each other.
  # Not itself a window, but moved onto display-ready.target along with
  # non-mixer-xt/touchosc: it has to start after non-mixer-xt (OSC routing)
  # and before touchosc (OSC routes), both of which are now also gated on
  # display-ready.target, so it needs to be on the same gate rather than
  # racing ahead of them via its own graphical-session.target trigger.
  systemd.user.services.midi-daemon = {
    Unit = {
      Description = "MIDI Lua Routing Daemon";
      After = [ "graphical-session.target" "display-ready.target" "non-mixer-xt.service" "pipewire.service" "wireplumber.service" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitIntervalSec = 60;
      StartLimitBurst = 5;
    };
    Service = {
      Type = "simple";
      ExecStart =
        "${pkgs.midi-daemon}/bin/midi-daemon --config /etc/midi-daemon/config.toml --routes /etc/midi-daemon/routes.d";
      Restart = "always";
      RestartSec = 2;
      RestartSteps = 4;
      RestartMaxDelaySec = "32s";
      TimeoutStopSec = 30;
      RuntimeDirectory = "midi-daemon";
      CacheDirectory = "midi-daemon";
      Environment = "RUST_LOG=midi_daemon=info";
    };
  };

  # Moved from xmonad's startupHook: previously spawned on login via spawnOn
  # "U13", now started as a user service (like non-mixer-xt/midi-daemon)
  # and pinned to U13 by WM_CLASS in xmonad's manageHook instead.
  #
  # Disabled 2026-10-14: TouchOSC pins a full CPU core continuously, with
  # ANY layout (confirmed with a blank .tosc, not specific to
  # ComplexSetup.tosc or its scripts), across every render backend
  # (GL2/GL3/ES2/software llvmpipe), with picom stopped entirely, and on
  # both the packaged 1.4.9.248 and the latest upstream 1.5.3.266 -- it's
  # not blocking on vsync/frame presentation at all, just rendering flat
  # out. Not fixable from this config; re-enable once Hexler ships a fix
  # upstream. Not actively used right now anyway.
  # systemd.user.services.touchosc = {
  #   Unit = {
  #     Description = "TouchOSC (ComplexSetup project)";
  #     # rclone-dropbox.service: same reasoning as non-mixer-xt above --
  #     # without it TouchOSC can start before the Dropbox mount is ready and
  #     # map a degraded window that doShift then pins to U13.
  #     # Not WantedBy anything -- only started via display-ready.target (see
  #     # home.nix). TouchOSC reads display geometry once at startup and never
  #     # re-checks it, so ordering alone (After=autorandr.service) wasn't
  #     # enough: it could still start against a not-yet-corrected profile
  #     # from the login race those commits fixed (37b1528, 0c7d079), and
  #     # unlike midi-staff-trainer this needs a full exit+relaunch to pick up
  #     # the right geometry -- an XMonad relayout alone doesn't fix it.
  #     After = [ "graphical-session.target" "display-ready.target" "midi-daemon.service" "rclone-dropbox.service" ];
  #     Requires = [ "rclone-dropbox.service" ];
  #     PartOf = [ "graphical-session.target" ];
  #     StartLimitIntervalSec = 60;
  #     StartLimitBurst = 5;
  #   };
  #   Service = {
  #     Type = "simple";
  #     ExecStart =
  #       "${pkgs.touchosc}/bin/TouchOSC --general.ui.editor=false --general.ui.fullscreen=true /home/fprice/.config/touchosc/ComplexSetup.tosc";
  #     Restart = "always";
  #     RestartSec = 2;
  #     RestartSteps = 4;
  #     RestartMaxDelaySec = "32s";
  #     TimeoutStopSec = 10;
  #   };
  # };
}
