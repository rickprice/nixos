{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # CLI essentials
    wl-clipboard # Wayland clipboard (wl-copy / wl-paste) for Neovim
    xclip # X11 clipboard for Neovim
    wmctrl # X11 window manager control
    xdotool # X11 window/input automation
    ripgrep # fast grep
    fd # fast find
    bat # cat with syntax highlighting
    eza # modern ls
    fzf # fuzzy finder
    jq # JSON processor
    htop # process viewer
    curl
    wget
    unzip
    tree
    usbutils # lsusb

    # Dev tools
    git
    gh # GitHub CLI
    lazygit
    claude-code
    tree-sitter # tree-sitter CLI (nvim-treesitter health check)
    prettier # JS/TS/CSS/HTML/Markdown formatter (conform.nvim)
    gcc
    gnumake
    cmake
    pkg-config
    gdb
    clang-tools # clangd, clang-format, clang-tidy

    # Nixpkgs contribution tools
    nixfmt # official Nix formatter nixpkgs CI enforces
    nixpkgs-reviewFull # builds a PR/working-tree diff + reverse deps to confirm nothing broke
    nix-update # semi-automated version/hash bumps for package updates
    nix-tree # inspect dependency closures of built derivations
    statix # Nix anti-pattern linter
    deadnix # finds dead/unused Nix code

    # X11 development libraries (dev outputs include headers and .pc files)
    libx11.dev
    libxext.dev
    libxrender.dev
    libxrandr.dev
    libxcursor.dev
    libxi.dev
    libxinerama.dev
    libxfixes.dev
    libxcomposite.dev
    libxdamage.dev
    libxtst # no dev output
    libxft.dev
    libxcb.dev

    # Rust
    cargo
    rustc
    rust-analyzer

    # Python
    (python3.withPackages (
      ps: with ps; [
        ipython # enhanced REPL
        requests # HTTP client
        httpx # async HTTP client
        rich # terminal formatting
      ]
    ))

    # Audio production
    # Wrap Ardour so it links against PipeWire's JACK library instead of the
    # real JACK, for the same reason Carla and Guitarix are wrapped.
    (pkgs.symlinkJoin {
      name = "ardour";
      paths = [ pkgs.ardour ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/ardour9 \
          --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
      '';
    })
    calf
    guitarix-wrapped
    # Wrap Carla so it links against PipeWire's JACK library instead of the
    # real JACK. Without this, Carla's JACK backend can't connect to PipeWire
    # and the plugin scanner never initialises.
    (pkgs.symlinkJoin {
      name = "carla";
      paths = [ pkgs.carla ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/carla \
          --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
      '';
    })
    pkgs.pipewire.jack # provides pw-jack for running any JACK app under PipeWire
    qpwgraph
    midisnoop
    touchosc
    protokol # Hexler's MIDI/OSC/gamepad input monitor
    liblo # oscsend / oscdump / oscsendfile CLI tools for OSC debugging

    lsp-plugins
    sfizz-ui
    x42-plugins
    # x42-gmsynth
    # x42-avldrums
    dragonfly-reverb
    caps # Tim Goetze PlateX2 and others

    # Music notation
    musescore
    lilypond
    frescobaldi
    denemo
    rosegarden

    # nvim-lilypond-suite dependencies
    zathura # PDF viewer with auto-reload for the compile-view cycle
    fluidsynth # MIDI synthesizer (nvls player)
    soundfont-fluid # GM soundfont for fluidsynth
    ffmpeg # converts fluidsynth raw PCM output to mp3

    # My MIDI controller/OSC controller
    midi-daemon
    midi-staff-trainer
    name-time-period
    images-matching-subdirectories
    background-picker
    md-to-svg
    markdown-timesheet
    csvargs
    darktable-import-xmp
    (pkgs.writeShellScriptBin "BackupComputer" (builtins.readFile ../../scripts/BackupComputer.sh))
    (pkgs.writeShellScriptBin "ProcessRawImages" (builtins.readFile ../../scripts/ProcessRawImages.sh))

    # ProcessRawImages dependencies
    exiftool
    trash-cli

    volumepanningstereo-lv2

    # File manager
    pcmanfm
    gvfs # trash, network shares, MTP device support for pcmanfm
    lxmenu-data # applications menu in pcmanfm sidebar
    tumbler # D-Bus thumbnail service (images, fonts, PDF)
    ffmpegthumbnailer # video thumbnails via tumbler

    # Document viewer
    atril

    # Archive manager
    file-roller

    # Calculator
    gnome-calculator

    # Diff and merge tool
    meld

    # Media playback
    mpv

    # Office
    libreoffice
    hunspell
    hunspellDicts.en_CA
    _1password-gui

    # Internet
    google-chrome
    discord
    obsidian

    # Graphics
    darktable
    gimp
    inkscape
    rapidraw # RAW photo editor

    # Video editing
    kdePackages.kdenlive
    mediainfo # media info panel
    frei0r # video effects plugins
    glaxnimate # vector animation editor (title/animation tool)
    v4l-utils # webcam / capture card support
    opencv # motion tracking

    # Screen recording / streaming
    obs-studio

    # XMonad window manager utilities
    arandr
    (feh.override { inherit imlib2Full; })
    dmenu
    xmobar
    gsimplecal
    wezterm
    dunst
    trayer
    xkb-switch
    (pkgs.writeShellScriptBin "CopyQuarter" (builtins.readFile ../../scripts/CopyQuarter.sh))
    networkmanagerapplet
    xscreensaver
    udiskie
    blueman
    polkit_gnome
    xfce4-power-manager
    pasystray
    system-config-printer
    meteo-qt
    rclone
  ];
}
