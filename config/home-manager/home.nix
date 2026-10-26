_:

{
  home = {
    username = "fprice";
    homeDirectory = "/home/fprice";
    stateVersion = "26.05";
  };

  imports = [
    ./fprice/packages.nix
    ./fprice/shell.nix
    ./fprice/git.nix
    ./fprice/neovim.nix
    ./fprice/tmux.nix
    ./fprice/session-variables.nix
    ./fprice/mime-apps.nix
    ./fprice/wired.nix
    ./fprice/meteo-qt.nix
    ./fprice/chrome.nix
    ./fprice/xmonad.nix
    ./fprice/claude-skills.nix
    ./fprice/libfm.nix
    ./fprice/autorandr.nix
    ./fprice/discord.nix
    ./fprice/guitarix.nix
    ./fprice/obsidian.nix
    ./fprice/qpwgraph.nix
    ./fprice/midi-staff-trainer.nix
    ./fprice/dunst.nix
    ./fprice/xfce4-power-manager.nix
    ./fprice/picom.nix
    ./fprice/flameshot.nix
    ./fprice/tray-applets.nix
    ./fprice/rclone-dropbox.nix
    ./fprice/kwallet.nix
    ./fprice/xscreensaver.nix
    ./fprice/plasma.nix
  ];
}
