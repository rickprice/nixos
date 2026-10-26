_:

{
  programs.tmux = {
    enable = true;
    shortcut = "b"; # Ctrl-b prefix (default)
    escapeTime = 0;
    historyLimit = 10000;
    terminal = "screen-256color";
    extraConfig = ''
      set -g mouse on
      set -g base-index 1
    '';
  };
}
