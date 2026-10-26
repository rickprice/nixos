{ lib, pkgs, ... }:

{
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "bat";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";

    # Cargo / C build tools need to find X11 headers and .pc files in the Nix store
    PKG_CONFIG_PATH =
      (lib.makeSearchPathOutput "dev" "lib/pkgconfig" (
        with pkgs;
        [
          libx11.dev
          libxext.dev
          libxrender.dev
          libxrandr.dev
          libxcursor.dev
          libxi.dev
          libxinerama.dev
          libxfixes.dev
          libxcomposite.dev
          libxdamage.dev
          libxtst
          libxft.dev
          libxcb.dev
        ]
      ))
      + ":"
      +
        # xorgproto puts xproto.pc (and others) under share/pkgconfig, not lib/pkgconfig
        "${pkgs.xorgproto}/share/pkgconfig";
    LD_LIBRARY_PATH = lib.makeLibraryPath (
      with pkgs;
      [
        libx11.dev
        libxext.dev
        libxrender.dev
        libxrandr.dev
        libxcursor.dev
        libxi.dev
        libxinerama.dev
        libxfixes.dev
        libxcomposite.dev
        libxdamage.dev
        libxtst
        libxft.dev
        libxcb.dev
      ]
    );
  };
}
