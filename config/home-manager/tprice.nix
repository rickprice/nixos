{ config, pkgs, ... }:

{
  home.username = "tprice";
  home.homeDirectory = "/home/tprice";
  home.stateVersion = "26.05";

  # ── Packages ────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # CLI essentials
    wl-clipboard
    xclip
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    htop
    curl
    wget
    unzip
    tree

    # Dev tools
    git
    gh
    lazygit
    claude-code
    tree-sitter
    prettier

    # Python
    (python3.withPackages (ps: with ps; [
      ipython
      requests
      httpx
      black
      mypy
      pylint
      rich
    ]))

    # File manager
    pcmanfm
    gvfs
    lxmenu-data
    tumbler
    ffmpegthumbnailer

    # Document viewers
    atril
    zathura

    # Diff and merge tool
    meld

    # Media
    mpv
    ffmpeg

    # Internet
    google-chrome
    discord
    obsidian

    # Graphics
    darktable
    gimp
    inkscape

    # Autorandr background selection helpers
    name-time-period
    images-matching-subdirectories

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
      ls   = "eza";
      ll   = "eza -la";
      lt   = "eza --tree";
      cat  = "bat";
      grep = "rg";

      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#daw";
    };

    history = {
      size = 10000;
      save = 10000;
      ignoreDups = true;
      share = true;
    };

    initContent = ''
      [ -f ~/.ssh/id_ed25519 ] && eval "$(keychain --quiet --eval ~/.ssh/id_ed25519)"

      bindkey -v

      bindkey '^R' history-incremental-search-backward

      source ${pkgs.fzf}/share/fzf/key-bindings.zsh
      source ${pkgs.fzf}/share/fzf/completion.zsh
    '';
  };

  # ── ZOxide ──────────────────────────────────────────────────────────────────
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
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
        name  = "Tamara Price";
        email = "tprice@pricemail.ca";
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
    initLua = builtins.readFile ../nvim/init.lua;
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
        lua markdown markdown_inline python regex vim yaml
      ]))

      # UI / diagnostics
      noice-nvim
      nui-nvim
      nvim-notify
      nvim-web-devicons
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

      # Shared dependencies
      plenary-nvim
    ];
  };

  # ── Terminal multiplexer ─────────────────────────────────────────────────────
  programs.tmux = {
    enable = true;
    shortcut = "a";
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
  home.file.".config/xmonad/xmonad.hs".source = ../xmonad/xmonad-tprice.hs;
  home.file.".xmobarrc".source = ../xmobar/xmobarrc-tprice;

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

    # Add profiles here after running: autorandr --save <profile-name>
  };

  # ── Systemd user services ────────────────────────────────────────────────────

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
      timeout = 120;
    };

    powerdevil.AC = {
      displayBrightness = 40;
      turnOffDisplay.idleTimeout = 3600;
      autoSuspend.action = "nothing";
    };
  };

}
