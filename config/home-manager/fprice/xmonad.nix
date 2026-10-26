{
  config,
  lib,
  pkgs,
  ...
}:

{
  home = {
    file = {
      ".config/xmonad/xmonad.hs".source = ../../xmonad/xmonad.hs;
      ".config/touchosc/ComplexSetup.tosc".source =
        "${pkgs.midi-daemon}/share/doc/midi-daemon/examples/TouchOSC/ComplexSetup.tosc";
      ".xmobarrc".source = ../../xmobar/xmobarrc;
    };

    # Nix store files have epoch timestamps, so XMonad's mtime check thinks the
    # source is always older than the binary and skips recompilation. Deleting
    # the binary after each apply forces XMonad to recompile from the updated
    # source on the next login or Mod+Q restart. The compiled binary lives
    # under XMonad's XDG cache dir (~/.cache/xmonad), not ~/.config/xmonad --
    # deleting the wrong path here silently no-ops and leaves the stale cached
    # binary in place.
    activation.forceXmonadRecompile = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
      $DRY_RUN_CMD rm -f "${config.home.homeDirectory}/.cache/xmonad/xmonad-x86_64-linux"
      /run/current-system/sw/bin/xmonad --restart || true
    '';
  };

  xdg.configFile = {
    "gtk-3.0/gtk.css".text = ''
      calendar {
        font-size: 150%;
      }
    '';

    # xmobar bar is ~24px tall (TopW L 90 with Sans-12); yoffset pushes gsimplecal
    # below the bar instead of overlapping it when clicking the clock.
    "gsimplecal/config".text = ''
      mainwindow_yoffset = 30
    '';
  };
}
