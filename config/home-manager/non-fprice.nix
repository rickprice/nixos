{ pkgs, ... }:

{
  # Wrap non-mixer-xt's, non-timeline-xt's, and new-session-manager's
  # binaries so they link against PipeWire's JACK library instead of the
  # real JACK, for the same reason Ardour/Carla/Guitarix are wrapped.
  # nmxt-patch doesn't talk to JACK directly, but is wrapped too for
  # consistency since it's cheap to do so. Of new-session-manager's
  # binaries, only jackpatch links against JACK directly.
  home.packages = [
    (pkgs.symlinkJoin {
      name = "non-mixer-xt";
      paths = [ pkgs.non-mixer-xt ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for bin in non-mixer-xt midi-mapper-xt nmxt-plugin-scan nmxt-patch; do
          wrapProgram $out/bin/$bin \
            --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
        done
      '';
    })
    (pkgs.symlinkJoin {
      name = "non-timeline-xt";
      paths = [ pkgs.non-timeline-xt ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/non-timeline-xt \
          --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
      '';
    })
    (pkgs.symlinkJoin {
      name = "new-session-manager";
      paths = [ pkgs.new-session-manager ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/jackpatch \
          --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
      '';
    })
  ];
}
