{ config, pkgs, ... }:

{
  home.username = "fprice";
  home.homeDirectory = "/home/fprice";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    # Audio production
    ardour
    calf
    guitarix
    # hydrogen
    lsp-plugins
    # musescore
    carla
    qpwgraph
    midisnoop

    # Media playback
    mpv

    # Terminal utilities
    bat
    btop
    eza
    fd
    fzf
    ripgrep
    unzip
    wget

    # Git utilities
    lazygit

    # Fonts
    nerd-fonts.jetbrains-mono
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "Frederick Price";
      user.email = "fprice@pricemail.ca";
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  programs.zsh = {
    enable = true;
    shellAliases = {
      ls = "eza";
      ll = "eza -lah";
      cat = "bat";
    };
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.wezterm = {
    enable = true;
    enableZshIntegration = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      config.colors = {
        foreground = "#dedede",
        background = "black",
        cursor_bg = "#ffa560",
        cursor_border = "#ffa560",
        cursor_fg = "#ffffff",
        selection_bg = "#474e91",
        selection_fg = "#f4f4f4",
        ansi = { "#929292", "#e27373", "#94b979", "#ffba7b", "#97bedc", "#e1c0fa", "#00988e", "#dedede" },
        brights = { "#bdbdbd", "#ffa1a1", "#bddeab", "#ffdca0", "#b1d8f6", "#fbdaff", "#1ab2a8", "#ffffff" },
      }
      config.font = wezterm.font('JetBrainsMono Nerd Font', { weight = 'Regular' })
      config.font_size = 12.0
      config.hide_tab_bar_if_only_one_tab = true
      config.window_decorations = 'RESIZE'
      config.scrollback_lines = 10000
      config.window_padding = {
        left = 8,
        right = 8,
        top = 8,
        bottom = 8,
      }

      return config
    '';
  };
}
