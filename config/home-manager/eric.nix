{ config, pkgs, lib, ... }:

{
  home.username = "eric";
  home.homeDirectory = "/home/eric";
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
    tree-sitter
    prettier

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

    # XMonad window manager utilities
    arandr
    (feh.override { imlib2Full = imlib2Full; })
    dmenu
    xmobar
    wezterm
    dunst
    trayer
    xscreensaver
    cbatticon
    polkit_gnome
    xfce4-power-manager
    pasystray
    xkb-switch
    system-config-printer
    inappropriate-video-handler
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
    GDK_DPI_SCALE = "1.3";
    QT_SCALE_FACTOR = "1.3";
  };

  xresources.properties = {
    "Xft.dpi" = "125";
  };

  # ── XDG MIME associations ────────────────────────────────────────────────────
  xdg.configFile."mimeapps.list".force = true;
  xdg.dataFile."applications/mimeapps.list".force = true;

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "image/bmp"                = "feh.desktop";
      "image/gif"                = "feh.desktop";
      "image/heic"               = "feh.desktop";
      "image/jpeg"               = "feh.desktop";
      "image/jpg"                = "feh.desktop";
      "image/pjpeg"              = "feh.desktop";
      "image/png"                = "feh.desktop";
      "image/tiff"               = "feh.desktop";
      "image/webp"               = "feh.desktop";
      "image/x-bmp"              = "feh.desktop";
      "image/x-pcx"              = "feh.desktop";
      "image/x-png"              = "feh.desktop";
      "image/x-portable-anymap"  = "feh.desktop";
      "image/x-portable-bitmap"  = "feh.desktop";
      "image/x-portable-graymap" = "feh.desktop";
      "image/x-portable-pixmap"  = "feh.desktop";
      "image/x-tga"              = "feh.desktop";
      "image/x-xbitmap"          = "feh.desktop";
      "application/pdf"          = "atril.desktop";
      "application/x-bzpdf"      = "atril.desktop";
      "application/x-gzpdf"      = "atril.desktop";
      "application/x-xzpdf"      = "atril.desktop";
    };
  };

  # ── Wired ────────────────────────────────────────────────────────────────────
  xdg.configFile."wired/wired.ron".text = ''
    (
    	max_notifications: 10,
    	timeout: 10000,
    	poll_interval: 16,
    	shortcuts: (
    		notification_interact: 2,
    		notification_close: 1,
    		notification_closeall: 3,
    	),
    	history_length: 100,
    	replacing_resets_timeout: true,
    	min_window_width: 768,
    	layout_blocks: [
    		(
    			name: "root",
    			parent: "",
    			hook: (parent_anchor: TL, self_anchor: TL),
    			offset: (x: 0, y: 48),
    			params: NotificationBlock((
    				monitor: -1,
                    focus_follows: Window,
    				border_width: 3.0,
    				border_rounding: 0.0,
    				gap: (x: 0.0, y: 24.0),
    				background_color: (hex: "#1D1F21"),
    				border_color: (hex: "#66D9EF"),
    				border_color_low: (hex: "#403D3D"),
    				border_color_critical: (hex: "#661512"),
    				notification_hook: (parent_anchor: BL, self_anchor: TL),
    			)),
    		),
    		(
    			name: "image",
    			parent: "summary",
    			hook: (parent_anchor: TL, self_anchor: TR),
    			offset: (x: 0, y: 0),
    			render_criteria: [ HintImage ],
    			params: ImageBlock((
    				image_type: Hint,
    				padding: (left: 0.0, right: 24.0, top: 24.0, bottom: 24.0),
    				rounding: 0.0,
    				scale_width: 144,
    				scale_height: 144,
    				filter_mode: Lanczos3,
    			)),
    		),
    		(
    			name: "summary",
    			parent: "root",
    			offset: (x: 0, y: 0),
    			hook: (parent_anchor: TR, self_anchor: TR),
    			params: TextBlock((
    				text: "%s",
    				padding: (left: 18.0, right: 18.0, top: 18.0, bottom: 12.0),
    				font: "Dejavu Sans 36",
    				color: Color(hex: "#f8f8f2"),
    				markup: Pango,
    				dimensions: (
    					width: (min: 768, max: 768),
    					height: (min: 0, max: 300),
    				),
    				dimensions_image_hint: (
    					width: (min: 600, max: 600),
    					height: (min: 0, max: 300),
    				),
    			)),
    		),
    		(
    			name: "body",
    			parent: "summary",
    			offset: (x: 0, y: 0),
    			hook: (parent_anchor: BL, self_anchor: TL),
    			render_criteria: [ Body ],
    			render_anti_criteria: [ AppName("progress") ],
    			params: ScrollingTextBlock((
    				text: "%b",
    				padding: (left: 18.0, right: 18.0, top: 0.0, bottom: 24.0),
    				font: "DejaVu Sans 36",
    				color: (hex: "#f8f8f2"),
    				markup: Pango,
    				scroll_speed: 0.1,
    				lhs_dist: 24.0,
    				rhs_dist: 24.0,
    				scroll_t: 1.0,
    				width: (min: 768, max: 768),
    				width_image_hint: (min: 544, max: 544),
    			)),
    		),
    		(
    			name: "progress",
    			parent: "body",
    			offset: (x: 0, y: 0),
    			hook: (parent_anchor: BL, self_anchor: TL),
    			render_criteria: [ Progress ],
    			render_anti_criteria: [ Body ],
    			params: ProgressBlock((
    				padding: (left: 18.0, right: 18.0, top: 15.0, bottom: 42.0),
    				border_width: 0.0,
    				border_rounding: 0.0,
    				fill_rounding: 0.0,
    				border_color: (hex: "#1D1F21"),
    				background_color: (hex: "#403D3D"),
    				fill_color: (hex: "#66D9EF"),
    				width: 705.0,
    				height: 24.0,
    			)),
    		),
    		(
    			name: "progress_muted",
    			parent: "body",
    			offset: (x: 0, y: 0),
    			hook: (parent_anchor: BL, self_anchor: TL),
    			render_criteria: [ And([Progress, Body]) ],
    			params: ProgressBlock((
    				padding: (left: 18.0, right: 18.0, top: 15.0, bottom: 42.0),
    				border_width: 0.0,
    				border_rounding: 0.0,
    				fill_rounding: 0.0,
    				border_color: (hex: "#1D1F21"),
    				background_color: (hex: "#403D3D"),
    				fill_color: (hex: "#64888F"),
    				width: 705.0,
    				height: 24.0,
    			)),
    		),
    	],
    )
  '';

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
  home.file.".config/xmonad/xmonad.hs".source = ../xmonad/xmonad-eric.hs;

  home.activation.forceXmonadRecompile = lib.hm.dag.entryAfter ["linkGeneration"] ''
    $DRY_RUN_CMD rm -f "${config.home.homeDirectory}/.config/xmonad/xmonad-x86_64-linux"
    /run/current-system/sw/bin/xmonad --restart || true
  '';
  home.file.".xmobarrc".source = ../xmobar/xmobarrc-eric;

  # ── Autorandr ────────────────────────────────────────────────────────────────
  programs.autorandr = {
    enable = true;

    hooks.postswitch."05_set_keyboard" = ''
      #! /usr/bin/bash
      setxkbmap -layout us
    '';

    # Add profiles here after running: autorandr --save <profile-name>
  };

  # ── Inappropriate Video Handler ──────────────────────────────────────────────
  xdg.configFile."inappropriate-video-handler/BlackList.txt".source = ../innapropriate-video-handler/BlackList.txt;
  xdg.configFile."inappropriate-video-handler/WhiteList.txt".source = ../innapropriate-video-handler/WhiteList.txt;
  xdg.configFile."inappropriate-video-handler/wallpaper/blocked.jpg".source = ../innapropriate-video-handler/wallpaper/blocked.jpg;
  xdg.configFile."inappropriate-video-handler/wallpaper/normal.jpg".source = ../innapropriate-video-handler/wallpaper/normal.jpg;
  xdg.configFile."inappropriate-video-handler/wallpaper/break.jpg".source = ../innapropriate-video-handler/wallpaper/break.jpg;

  # ── Dunst ────────────────────────────────────────────────────────────────────
  xdg.configFile."dunst/dunstrc".text = ''
    [global]
    font = DejaVu Sans 18
  '';

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

  systemd.user.services.cbatticon = {
    Unit = {
      Description = "Battery status tray icon";
      After = [ "graphical-session.target" "trayer.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.cbatticon}/bin/cbatticon";
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
      Type = "dbus";
      BusName = "org.kde.kwalletd6";
      ExecStart = "${pkgs.kdePackages.kwallet}/bin/kwalletd6";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.kwallet-pam-unlock = {
    Unit = {
      Description = "Unlock KWallet from PAM credentials";
      After = [ "kwalletd6.service" ];
      Requires = [ "kwalletd6.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.kdePackages.kwallet-pam}/libexec/pam_kwallet_init";
      RemainAfterExit = false;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.xscreensaver-keyboard-fix = {
    Unit = {
      Description = "Re-apply keyboard layout after xscreensaver deactivates";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.bash}/bin/bash -c 'until ${pkgs.xscreensaver}/bin/xscreensaver-command -version &>/dev/null; do sleep 2; done; ${pkgs.xscreensaver}/bin/xscreensaver-command -watch | while read event; do case \"$event\" in UNBLANK*|AUTH*) ${pkgs.setxkbmap}/bin/setxkbmap -layout us ;; esac; done'";
      Restart = "on-failure";
      RestartSec = 3;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.inappropriate-video-handler = {
    Unit = {
      Description = "Inappropriate Video Handler daemon";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.inappropriate-video-handler}/bin/inappropriate-video-handler";
      Restart = "on-failure";
      RestartSec = 5;
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

  systemd.user.services.trayer = {
    Unit = {
      Description = "Trayer system tray";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.trayer}/bin/trayer --edge top --align right --widthtype request --SetDockType true --SetPartialStrut true --expand true --tint 0x000000 --height 36";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.pasystray = {
    Unit = {
      Description = "PulseAudio system tray";
      After = [ "graphical-session.target" "trayer.service" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.pasystray}/bin/pasystray";
      Restart = "on-failure";
      RestartSec = 2;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.xscreensaver = {
    Unit = {
      Description = "XScreensaver screen locker";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.xscreensaver}/bin/xscreensaver --no-splash";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  home.file.".xscreensaver" = {
    force = true;
    text = ''
    timeout:       0:10:00
    cycle:         0:10:00
    lock:          False
    passwdTimeout: 0:00:30
    mode:          random
    selected:      -1
    programs: \
        maze --root \n\
      GL: superquadrics --root \n\
        attraction --root \n\
    -   blitspin --root \n\
        greynetic --root \n\
        helix --root \n\
        hopalong --root \n\
        imsmap --root \n\
    -   noseguy --root \n\
    -   pyro --root \n\
        qix --root \n\
    -   rocks --root \n\
        rorschach --root \n\
    -   decayscreen --root \n\
        flame --root \n\
        halo --root \n\
        slidescreen --root \n\
        pedal --root \n\
        bouboule --root \n\
        braid --root \n\
        coral --root \n\
        deco --root \n\
        drift --root \n\
    -   fadeplot --root \n\
        galaxy --root \n\
        goop --root \n\
        grav --root \n\
        ifs --root \n\
      GL: jigsaw --root \n\
        julia --root \n\
        kaleidescope --root \n\
      GL: moebius --root \n\
        moire --root \n\
      GL: morph3d --root \n\
        mountain --root \n\
        munch --root \n\
        penrose --root \n\
      GL: pipes --root \n\
        rdbomb --root \n\
      GL: rubik --root \n\
    -   sierpinski --root \n\
    -   slip --root \n\
      GL: sproingies --root \n\
        starfish --root \n\
        strange --root \n\
        swirl --root \n\
        triangle --root \n\
        xjack --root \n\
        xlyap --root \n\
      GL: atlantis --root \n\
    -   bsod --root \n\
      GL: bubble3d --root \n\
      GL: cage --root \n\
    -   crystal --root \n\
        cynosure --root \n\
        discrete --root \n\
    -   distort --root \n\
        epicycle --root \n\
        flow --root \n\
      GL: glplanet --root \n\
        interference --root \n\
        kumppa --root \n\
    - GL: lament --root \n\
        moire2 --root \n\
    - GL: sonar --root \n\
      GL: stairs --root \n\
        truchet --root \n\
    -   vidwhacker --root \n\
    -   webcollage --root \n\
        blaster --root \n\
        bumps --root \n\
        ccurve --root \n\
        compass --root \n\
    -   deluxe --root \n\
    -   demon --root \n\
      GL: extrusion --root \n\
    -   loop --root \n\
    -   penetrate --root \n\
        petri --root \n\
        phosphor --root \n\
      GL: pulsar --root \n\
    -   ripples --root \n\
        shadebobs --root \n\
      GL: sierpinski3d --root \n\
    -   spotlight --root \n\
        squiral --root \n\
        wander --root \n\
    -   xflame --root \n\
        xmatrix --root \n\
      GL: gflux --root \n\
    -   nerverot --root \n\
        xrayswarm --root \n\
        xspirograph --root \n\
    - GL: circuit --root \n\
    - GL: dangerball --root \n\
    - GL: dnalogo --root \n\
      GL: engine --root \n\
      GL: flipscreen3d --root \n\
      GL: gltext --root \n\
      GL: menger --root \n\
    - GL: molecule --root \n\
    -   rotzoomer --root \n\
        scooter --root \n\
        speedmine --root \n\
      GL: starwars --root \n\
      GL: stonerview --root \n\
        vermiculate --root \n\
        whirlwindwarp --root \n\
    -   zoom --root \n\
        anemone --root \n\
        apollonian --root \n\
      GL: boxed --root \n\
      GL: cubenetic --root \n\
      GL: endgame --root \n\
        euler2d --root \n\
        fluidballs --root \n\
      GL: flurry --root \n\
    - GL: glblur --root \n\
      GL: glsnake --root \n\
        halftone --root \n\
      GL: juggler3d --root \n\
      GL: lavalite --root \n\
    -   polyominoes --root \n\
      GL: queens --root \n\
    - GL: sballs --root \n\
      GL: spheremonics --root \n\
        twang --root \n\
      GL: antspotlight --root \n\
    -   apple2 --root \n\
      GL: atunnel --root \n\
    -   barcode --root \n\
      GL: blinkbox --root \n\
      GL: blocktube --root \n\
    - GL: bouncingcow --root \n\
        cloudlife --root \n\
      GL: cubestorm --root \n\
        eruption --root \n\
      GL: flipflop --root \n\
      GL: flyingtoasters --root \n\
        fontglide --root \n\
    - GL: gleidescope --root \n\
      GL: glknots --root \n\
      GL: glmatrix --root \n\
    - GL: glslideshow --root \n\
      GL: hypertorus --root \n\
    - GL: jigglypuff --root \n\
        metaballs --root \n\
    - GL: mirrorblob --root \n\
        piecewise --root \n\
      GL: polytopes --root \n\
        pong --root \n\
        popsquares --root \n\
      GL: surfaces --root \n\
    -   xanalogtv --root \n\
        abstractile --root \n\
        anemotaxis --root \n\
      GL: antinspect --root \n\
        fireworkx --root \n\
        fuzzyflakes --root \n\
        interaggregate --root \n\
        intermomentary --root \n\
    -   memscroller --root \n\
      GL: noof --root \n\
        pacman --root \n\
      GL: pinion --root \n\
      GL: polyhedra --root \n\
    - GL: providence --root \n\
        substrate --root \n\
        wormhole --root \n\
      GL: antmaze --root \n\
      GL: boing --root \n\
        boxfit --root \n\
    - GL: carousel --root \n\
        celtic --root \n\
      GL: crackberg --root \n\
      GL: cube21 --root \n\
        fiberlamp --root \n\
    - GL: fliptext --root \n\
      GL: glhanoi --root \n\
      GL: tangram --root \n\
      GL: timetunnel --root \n\
      GL: glschool --root \n\
      GL: topblock --root \n\
      GL: cubicgrid --root \n\
        cwaves --root \n\
      GL: gears --root \n\
    - GL: glcells --root \n\
      GL: lockward --root \n\
        m6502 --root \n\
      GL: moebiusgears --root \n\
      GL: voronoi --root \n\
      GL: hypnowheel --root \n\
      GL: klein --root \n\
    -   lcdscrub --root \n\
    - GL: photopile --root \n\
      GL: skytentacles --root \n\
      GL: rubikblocks --root \n\
      GL: companioncube --root \n\
      GL: hilbert --root \n\
      GL: tronbit --root \n\
      GL: geodesic --root \n\
        hexadrop --root \n\
      GL: kaleidocycle --root \n\
      GL: quasicrystal --root \n\
      GL: unknownpleasures --root \n\
        binaryring --root \n\
      GL: cityflow --root \n\
      GL: geodesicgears --root \n\
      GL: projectiveplane --root \n\
      GL: romanboy --root \n\
    -   tessellimage --root \n\
      GL: winduprobot --root \n\
      GL: splitflap --root \n\
      GL: cubestack --root \n\
      GL: cubetwist --root \n\
      GL: discoball --root \n\
      GL: dymaxionmap --root \n\
      GL: energystream --root \n\
      GL: hexstrut --root \n\
      GL: hydrostat --root \n\
      GL: raverhoop --root \n\
      GL: splodesic --root \n\
      GL: unicrud --root \n\
    - GL: esper --root \n\
    - GL: vigilance --root \n\
      GL: crumbler --root \n\
        filmleader --root \n\
    -   glitchpeg --root \n\
    - GL: handsy --root \n\
      GL: maze3d --root \n\
    - GL: peepers --root \n\
      GL: razzledazzle --root \n\
    -   vfeedback --root \n\
      GL: deepstars --root \n\
      GL: gravitywell --root \n\
      GL: beats --root \n\
      GL: covid19 --root \n\
      GL: etruscanvenus --root \n\
      GL: gibson --root \n\
    - GL: headroom --root \n\
      GL: sphereeversion --root \n\
        binaryhorizon --root \n\
        marbling --root \n\
    - GL: chompytower --root \n\
      GL: hextrail --root \n\
      GL: mapscroller --root \n\
      GL: nakagin --root \n\
    - GL: squirtorus --root \n\
      GL: cubocteversion --root \n\
    -   droste --root \n\
      GL: papercube --root \n\
    - GL: skulloop --root \n\
      GL: highvoltage --root \n\
      GL: kallisti --root \n\
    - GL: klondike --root \n\
    - GL: dumpsterfire --root \n\
      GL: hopffibration --root \n\
      GL: platonicfolding --root \n
    '';
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

  # Write xfce4-power-manager config directly to avoid requiring xfconfd at activation time
  xdg.configFile."xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml".text = ''
    <?xml version="1.0" encoding="UTF-8"?>
    <channel name="xfce4-power-manager" version="1.0">
      <property name="xfce4-power-manager" type="empty">
        <property name="power-button-action" type="uint" value="3"/>
      </property>
    </channel>
  '';

}
