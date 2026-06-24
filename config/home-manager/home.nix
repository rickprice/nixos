{ config, pkgs, ... }:

let
  # Extract the dark-variant tray SVGs from the maestral-gui package and install
  # them as named hicolor theme icons so maestral_qt's QIcon::hasThemeIcon() finds
  # them before falling back to screen pixel-sampling (which defaults to white
  # icons on XMonad because Qt screenshots return all-black pixels there).
  maestralIconsDark = pkgs.runCommand "maestral-tray-icons-dark" {} ''
    resources=$(echo ${pkgs.maestral-gui}/lib/python*/site-packages/maestral_qt/resources)
    mkdir -p $out
    for status in idle syncing paused disconnected info error; do
      cp "$resources/maestral_tray-$status-dark.svg" "$out/maestral_tray-$status.svg"
    done
  '';
  maestralStatuses = [ "idle" "syncing" "paused" "disconnected" "info" "error" ];
in

{
  home.username = "fprice";
  home.homeDirectory = "/home/fprice";
  home.stateVersion = "26.05";

  # ── Packages ────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # CLI essentials
    wl-clipboard  # Wayland clipboard (wl-copy / wl-paste) for Neovim
    xclip         # X11 clipboard for Neovim
    ripgrep       # fast grep
    fd            # fast find
    bat           # cat with syntax highlighting
    eza           # modern ls
    fzf           # fuzzy finder
    jq            # JSON processor
    htop          # process viewer
    curl
    wget
    unzip
    tree

    # Dev tools
    git
    gh            # GitHub CLI
    lazygit
    claude-code
    tree-sitter   # tree-sitter CLI (nvim-treesitter health check)
    prettier      # JS/TS/CSS/HTML/Markdown formatter (conform.nvim)

    # Rust
    cargo
    rustc
    rustfmt
    clippy
    rust-analyzer

    # Python
    (python3.withPackages (ps: with ps; [
      ipython       # enhanced REPL
      requests      # HTTP client
      httpx         # async HTTP client
      black         # formatter
      mypy          # type checker
      pylint        # linter
      rich          # terminal formatting
    ]))

    # Audio production
    ardour
    calf
    guitarix
    carla
    qpwgraph
    midisnoop
    touchosc

    lsp-plugins
    sfizz
    # sfizz-ui
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
    zathura          # PDF viewer with auto-reload for the compile-view cycle
    fluidsynth       # MIDI synthesizer (nvls player)
    soundfont-fluid  # GM soundfont for fluidsynth
    ffmpeg           # converts fluidsynth raw PCM output to mp3

    # My MIDI controller/OSC controller
    midi-daemon
    name-time-period
    images-matching-subdirectories
    background-picker
    md-to-svg
    markdown-timesheet
    csvargs

    volumepanningstereo-lv2

    # File manager
    pcmanfm
    gvfs              # trash, network shares, MTP device support for pcmanfm
    lxmenu-data       # applications menu in pcmanfm sidebar
    tumbler           # D-Bus thumbnail service (images, fonts, PDF)
    ffmpegthumbnailer # video thumbnails via tumbler

    # Document viewer
    atril

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

    # XMonad window manager utilities
    feh
    dmenu
    xmobar
    wezterm
    dunst
    trayer
    networkmanagerapplet
    xscreensaver
    udiskie
    cbatticon
    blueman
    polkit_gnome
    xfce4-power-manager
    pasystray
    meteo-qt
    syncthing
  ];

  # ── Shell ───────────────────────────────────────────────────────────────────
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ls  = "eza";
      ll  = "eza -la";
      lt  = "eza --tree";
      cat = "bat";
      grep = "rg";

      # NixOS shortcuts
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#daw";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;      # share history across terminals
    };

    initContent = ''
      eval "$(keychain --quiet --eval ~/.ssh/id_ed25519)"

      # Vi mode
      bindkey -v   # emacs keybindings (change to -v for vi)

      # Better history search
      bindkey '^R' history-incremental-search-backward

      # fzf keybindings
      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh
    '';
  };

  # ── ZOxide ──────────────────────────────────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true; # Compiles hooks straight into Zsh
  };


  # ── Prompt ──────────────────────────────────────────────────────────────────
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      character = {
        success_symbol = "[❯](green)";
        error_symbol   = "[❯](red)";
      };
      directory = {
        truncation_length = 3;
        truncate_to_repo = true;
      };

      git_branch = {
        symbol = " ";
      };

      package.disabled = true;
    };
  };

  # ── Git ─────────────────────────────────────────────────────────────────────
  programs.git = {
    enable = true;
    settings = {
        user = {
          name  = "Frederick Price";
          email = "fprice@pricemail.ca";
        };
      extraConfig = {
        init.defaultBranch = "main";
        pull.rebase = true;
        core.editor = "nvim";
      };
      aliases = {
        st = "status";
        co = "checkout";
        lg = "log --oneline --graph --decorate";
      };
    };
  };

  # ── Editor ──────────────────────────────────────────────────────────────────
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    initLua = (builtins.readFile ../nvim/init.lua) + ''

      -- ── nvim-lilypond-suite ───────────────────────────────────────────────────
      require("nvls").setup({
        lilypond = {
          options = {
            pdf_viewer = "zathura",
          },
        },
        player = {
          options = {
            midi_synth       = "fluidsynth",
            audio_format     = "mp3",
            fluidsynth_flags = { "${pkgs.soundfont-fluid}/share/soundfonts/FluidR3_GM2-2.sf2" },
          },
        },
      })
    '';
    plugins = with pkgs.vimPlugins; [
      # Completion
      blink-cmp
      friendly-snippets

      # Colorscheme
      nightfox-nvim

      # File types
      csv-vim

      # Formatting
      conform-nvim

      # Git
      gitsigns-nvim
      neogit
      diffview-nvim

      # Navigation
      hop-nvim
      telescope-nvim

      # Marks
      marks-nvim

      # LSP
      mason-nvim
      nvim-lspconfig
      typescript-tools-nvim

      # Treesitter with grammars
      (nvim-treesitter.withPlugins (p: with p; [
        bash typescript tsx javascript json html css scss
        lua markdown markdown_inline python regex vim yaml rust haskell
      ]))

      # UI / diagnostics
      noice-nvim
      nui-nvim          # required by noice
      nvim-notify       # required by noice
      nvim-web-devicons # icons for telescope, trouble, etc.
      rainbow-delimiters-nvim
      symbols-outline-nvim
      todo-comments-nvim
      trouble-nvim
      which-key-nvim
      zen-mode-nvim

      # Editing
      nvim-autopairs
      toggleterm-nvim
      vim-fetch

      # Debugging
      nvim-dap
      nvim-dap-ui
      nvim-nio

      # Notes
      obsidian-nvim

      # LilyPond
      nvim-lilypond-suite

      # Shared dependencies
      plenary-nvim
    ];
  };

  # ── Terminal multiplexer ─────────────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    shortcut = "a";          # Ctrl-a prefix
    escapeTime = 0;
    historyLimit = 10000;
    terminal = "screen-256color";
    extraConfig = ''
      set -g mouse on
      set -g base-index 1
    '';
  };

  # ── Environment variables ────────────────────────────────────────────────────
  home.sessionVariables = {
    EDITOR  = "nvim";
    VISUAL  = "nvim";
    PAGER   = "bat";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };


  # ── Maestral Qt tray icons (light theme / dark icons) ───────────────────────
  xdg.dataFile = builtins.listToAttrs (map (status: {
    name = "icons/hicolor/scalable/status/maestral_tray-${status}.svg";
    value.source = "${maestralIconsDark}/maestral_tray-${status}.svg";
  }) maestralStatuses);

  # ── meteo-qt ─────────────────────────────────────────────────────────────────
  xdg.configFile."meteo-qt/meteo-qt.conf".text = ''
    [General]
    APPID=30139089f1f08b98e4c16ef46f884148
    CitiesTranslation={}
    City=Midland
    CityList=['Midland_CA_6073363']
    Country=CA
    FontTray="Sans Serif,36,-1,5,50,0,0,0,0,0"
    ID=6073363
    IconsTheme=OpenWeatherMap
    Interval=120
    Proxy=False
    SystemIcons=hicolor
    Toggle_tray_interval=0
    Tray=Temperature
    TrayColor=#000000
    TrayType=temp
    Unit=metric
    Wind_unit=df

    [Logging]
    Level=INFO
  '';

  # ── XMonad ───────────────────────────────────────────────────────────────────
  home.file.".config/xmonad/xmonad.hs".source = ../xmonad/xmonad.hs;
  home.file.".xmobarrc".source = ../xmobar/xmobarrc;

  # ── Autorandr ────────────────────────────────────────────────────────────────
  programs.autorandr = {
    enable = true;

    hooks.postswitch."10_setup_feh" = ''
      #! /usr/bin/bash
      set -e
      trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
      trap 'echo "\"''${last_command}\" command failed with exit code $?."' EXIT
      DROPBOX_LOCATION=$(find ~/Documents -type d -name Dropbox)
      BACKGROUNDS_DIR="$DROPBOX_LOCATION/Pictures/SharedBackgrounds"
      PERSON_SPECIFIC="''${USER}Specific"
      THEME_DIRS="$PERSON_SPECIFIC Default $(name_time_period)"
      echo "DROPBOX_LOCATION is: " $DROPBOX_LOCATION
      echo "BACKGROUNDS_DIR is: " $BACKGROUNDS_DIR
      echo "PERSON_SPECIFIC is: " $PERSON_SPECIFIC
      echo "THEME_DIRS are: " $THEME_DIRS
      feh --no-fehbg --bg-max $(images_matching_subdirectories --names-only --limit 4 $BACKGROUNDS_DIR $THEME_DIRS)
    '';

    profiles = {
      docked = {
        fingerprint = {
          "DisplayPort-0" = "00ffffffffffff001e6d0c5cb326070003200103803c1978ea24e5ae5048a4240e5054256b007140818081c0a9c0b300d1c08100d1cfcd4600a0a0381f4030203a0059fe2000001a023a801871382d40582c450059fe2000001e000000fd00384b1e5a18010a202020202020000000fc004c4720554c545241574944450a0128020331f2230907074b100403011f1359125d5e5f830100006d030c001000b83c200060010203e305c000e60605014a4a56295900a0a038274030203a0059fe2000001a565e00a0a0a029503020350059fe2000001a000000ff003230334e54435a44533635390a000000000000000000000000000000000000000000000000bf";
          "DisplayPort-1" = "00ffffffffffff0006b3d227827c0000311e0103803c22782ae925a4554f9a260e5054bfef00d1c0b30095008180814081c0714f0101023a801871382d40582c450056502100001e000000ff004c434c4d54463033313837340a000000fd00304b185412000a202020202020000000fc004153555520564132374548450a01e002032b714f0102031112130414050e0f1d1e1f90230917078301000065030c001000681a00000101304be66842806a703827400820980456502100001a011d007251d01e206e28550056502100001e011d00bc52d01e20b828554056502100001e8c0ad090204031200c405500565021000018000000000000000000000000b7";
          "DisplayPort-2" = "00ffffffffffff0010ac15d04c30473206110103802f1e78ee8f30a355499827145054a54b00714f81800101010101010101010101017c2e90a0601a1e4030203600d9281100001a000000ff004b553331313732373247304c0a000000fd00384b1e530e000a202020202020000000fc0044454c4c20453232385746500a00d9";
          "HDMI-A-0" = "00ffffffffffff004c2db571000e0001011f0103805f36780aa833ab5045a5270d4848bdef80714f81c0810081809500a9c0b300d1c008e80030f2705a80b0588a00501d7400001e565e00a0a0a0295030203500501d7400001a000000fd00184b0f873c000a202020202020000000fc0053414d53554e470a202020202001ed02035cf05661101f041305142021225d5e5f6065666264071603122f0f5707150750570700675400090707832f0000e2004fe305c3016e030c001000b83c2800800102030468d85dc40178800b02e3060d01e30f01e0e5018b849001023a801871382d40582c450000000000001e000000000000000000000000000000000077";
        };
        config = {
          "HDMI-A-0" = {
            crtc = 2;
            mode = "3840x2160";
            position = "4240x0";
            rate = "60.00";
          };
          "DisplayPort-1" = {
            crtc = 0;
            mode = "1920x1080";
            position = "2320x15";
            primary = true;
            rate = "60.00";
          };
          "DisplayPort-2" = {
            crtc = 3;
            mode = "1680x1050";
            position = "0x1095";
            rate = "59.88";
          };
          "DisplayPort-0" = {
            crtc = 1;
            mode = "2560x1080";
            position = "1680x1095";
            rate = "59.98";
          };
        };
      };

      mobile = {
        fingerprint = {
          "eDP-1" = "00ffffffffffff0009e5db0700000000011c0104a51f1178027d50a657529f27125054000000010101010101010101010101010101013a3880de703828403020360035ae1000001afb2c80de703828403020360035ae1000001a000000fe00424f452043510a202020202020000000fe004e4531343046484d2d4e36310a0043";
        };
        config = {
          "DP-1" = { enable = false; };
          "HDMI-1" = { enable = false; };
          "DP-2" = { enable = false; };
          "DP-2-1" = { enable = false; };
          "DP-2-2" = { enable = false; };
          "DP-2-3" = { enable = false; };
          "DP-1-1" = { enable = false; };
          "DP-1-2" = { enable = false; };
          "DP-1-3" = { enable = false; };
          "eDP-1" = {
            crtc = 0;
            mode = "1920x1080";
            position = "0x0";
            primary = true;
            rate = "60.00";
          };
        };
      };

      "OneMonitor" = {
        fingerprint = {
          "DisplayPort-1" = "00ffffffffffff0010ac15d04c30473206110103802f1e78ee8f30a355499827145054a54b00714f81800101010101010101010101017c2e90a0601a1e4030203600d9281100001a000000ff004b553331313732373247304c0a000000fd00384b1e530e000a202020202020000000fc0044454c4c20453232385746500a00d9";
        };
        config = {
          "DisplayPort-0" = { enable = false; };
          "DisplayPort-2" = { enable = false; };
          "HDMI-A-0" = { enable = false; };
          "DisplayPort-1" = {
            crtc = 0;
            mode = "1680x1050";
            position = "0x0";
            primary = true;
            rate = "59.88";
          };
        };
      };

      "ThreeMonitors" = {
        fingerprint = {
          "DisplayPort-0" = "00ffffffffffff001e6d0c5cb326070003200103803c1978ea24e5ae5048a4240e5054256b007140818081c0a9c0b300d1c08100d1cfcd4600a0a0381f4030203a0059fe2000001a023a801871382d40582c450059fe2000001e000000fd00384b1e5a18010a202020202020000000fc004c4720554c545241574944450a0128020331f2230907074b100403011f1359125d5e5f830100006d030c001000b83c200060010203e305c000e60605014a4a56295900a0a038274030203a0059fe2000001a565e00a0a0a029503020350059fe2000001a000000ff003230334e54435a44533635390a000000000000000000000000000000000000000000000000bf";
          "DisplayPort-1" = "00ffffffffffff0010ac15d04c30473206110103802f1e78ee8f30a355499827145054a54b00714f81800101010101010101010101017c2e90a0601a1e4030203600d9281100001a000000ff004b553331313732373247304c0a000000fd00384b1e530e000a202020202020000000fc0044454c4c20453232385746500a00d9";
          "HDMI-A-0" = "00ffffffffffff0006b3d227827c0000311e0103803c22782ae925a4554f9a260e5054bfef00d1c0b30095008180814081c0714f0101023a801871382d40582c450056502100001e000000ff004c434c4d54463033313837340a000000fd00304b185412000a202020202020000000fc004153555520564132374548450a01e002032b714f0102031112130414050e0f1d1e1f90230917078301000065030c001000681a00000101304be66842806a703827400820980456502100001a011d007251d01e206e28550056502100001e011d00bc52d01e20b828554056502100001e8c0ad090204031200c405500565021000018000000000000000000000000b7";
        };
        config = {
          "DisplayPort-2" = { enable = false; };
          "HDMI-A-0" = {
            crtc = 0;
            mode = "1920x1080";
            position = "274x0";
            primary = true;
            rate = "60.00";
          };
          "DisplayPort-0" = {
            crtc = 1;
            mode = "2560x1080";
            position = "0x1080";
            rate = "59.98";
          };
          "DisplayPort-1" = {
            crtc = 2;
            mode = "1680x1050";
            position = "2560x1095";
            rate = "59.88";
          };
        };
      };
    };
  };

  # Dunst notification daemon
  systemd.user.services.dunst = {
    Unit = {
      Description = "Dunst notification daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.dunst}/bin/dunst";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # XFCE power manager
  systemd.user.services.xfce4-power-manager = {
    Unit = {
      Description = "XFCE4 Power Manager";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.xfce4-power-manager}/bin/xfce4-power-manager";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Syncthing file sync
  systemd.user.services.syncthing = {
    Unit = {
      Description = "Syncthing file synchronization";
      After = [ "graphical-session.target" "network.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.syncthing}/bin/syncthing serve --no-browser";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Picom compositor for XMonad
  systemd.user.services.picom = {
    Unit = {
      Description = "Picom X compositor";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.picom}/bin/picom --backend glx";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Blueman Bluetooth applet — waits for the trayer systray before starting
  systemd.user.services.blueman-applet = {
    Unit = {
      Description = "Blueman Bluetooth manager applet";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'until ${pkgs.procps}/bin/pgrep -x trayer > /dev/null; do sleep 1; done; sleep 2'";
      ExecStart = "${pkgs.blueman}/bin/blueman-applet";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Maestral Qt tray icon — waits for trayer before starting
  systemd.user.services.maestral-qt = {
    Unit = {
      Description = "Maestral Qt system tray icon";
      After = [ "graphical-session.target" "maestral.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'until ${pkgs.procps}/bin/pgrep -x trayer > /dev/null; do sleep 1; done; sleep 2'";
      ExecStart = "${pkgs.maestral-gui}/bin/maestral_qt";
      Restart = "on-failure";
      RestartSec = 5;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # KWallet daemon — provides a secrets store for apps that use the KWallet API
  systemd.user.services.kwalletd6 = {
    Unit = {
      Description = "KWallet password manager daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.kdePackages.kwallet}/bin/kwalletd6";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Polkit authentication agent for XMonad (the dotfiles xmonad.hs uses the
  # /usr/lib/polkit-gnome path which doesn't exist in NixOS; this service
  # starts the agent via systemd instead)
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    Unit = {
      Description = "polkit-gnome-authentication-agent-1";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # ── KDE Plasma ───────────────────────────────────────────────────────────────
  programs.plasma = {
    enable = true;

    kscreenlocker = {
      autoLock = true;
      timeout = 120;  # lock after 2 hours of inactivity (minutes)
    };

    powerdevil.AC = {
      displayBrightness = 40;
      turnOffDisplay.idleTimeout = 3600;  # turn off screen after 1 hour (seconds)
      autoSuspend.action = "nothing";     # disable automatic sleep/hibernate
    };
  };

}
