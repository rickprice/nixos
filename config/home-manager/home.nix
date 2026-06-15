{ config, pkgs, ... }:

{
  home.username = "fprice";
  home.homeDirectory = "/home/fprice";
  home.stateVersion = "26.05";

  # ── Packages ────────────────────────────────────────────────────────────────
  home.packages = with pkgs; [
    # CLI essentials
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

    # Dev tools
    git
    gh            # GitHub CLI
    lazygit
    claude-code

    # Audio production
    ardour
    calf
    guitarix
    lsp-plugins
    carla
    qpwgraph
    midisnoop
    touchosc

    # Media playback
    mpv

    # Internet
    google-chrome

    # Graphics
    darktable
    gimp
    inkscape

    # SSH key management
    keychain
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

  # ── KDE Plasma ───────────────────────────────────────────────────────────────
  programs.plasma = {
    enable = true;

    kscreenlocker = {
      autoLock = true;
      timeout = 120;  # lock after 2 hours of inactivity (minutes)
    };

    powerdevil.AC = {
      turnOffDisplay.idleTimeout = 3600;  # turn off screen after 1 hour (seconds)
      autoSuspend.action = "nothing";     # disable automatic sleep/hibernate
    };
  };

}
