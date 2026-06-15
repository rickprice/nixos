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
    hydrogen
    lsp-plugins
    musescore

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

    # Fonts
    nerd-fonts.jetbrains-mono
  ];

  programs.git = {
    enable = true;
    userName = "Frederick Price";
    userEmail = "fprice@pricemail.ca";
    extraConfig = {
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

      config.color_scheme = 'Tokyo Night'
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
