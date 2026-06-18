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

    # My MIDI controller/OSC controller
    midi-daemon

    volumepanningstereo-lv2

    # Media playback
    mpv

    # Internet
    google-chrome
    discord

    # Graphics
    darktable
    gimp
    inkscape

    # XMonad window manager utilities
    xmobar
    wezterm
    dunst
    trayer
    networkmanagerapplet
    xscreensaver
    autorandr
    udiskie
    cbatticon
    blueman
    polkit_gnome
    xfce4-power-manager
    pasystray
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

  # ── XMonad ───────────────────────────────────────────────────────────────────
  home.file.".config/xmonad/xmonad.hs".source = ../xmonad/xmonad.hs;
  home.file.".xmobarrc".source = ../xmobar/xmobarrc;

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
