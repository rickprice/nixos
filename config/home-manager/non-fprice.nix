{ pkgs, ... }:

{
  # Wrap the Non suite (non-mixer, non-sequencer, non-timeline/non-daw,
  # non-midi-mapper, jackpatch) so they link against PipeWire's JACK library
  # instead of the real JACK, for the same reason Ardour/Carla/Guitarix are
  # wrapped. non-session-manager, nsmd, and nsm-proxy don't talk to JACK
  # directly, so they're left unwrapped.
  home.packages = [
    (pkgs.symlinkJoin {
      name = "non";
      paths = [ pkgs.non ];
      nativeBuildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        for bin in jackpatch non-midi-mapper non-mixer non-sequencer non-timeline; do
          wrapProgram $out/bin/$bin \
            --prefix LD_LIBRARY_PATH : "${pkgs.pipewire.jack}/lib"
        done
      '';
    })
  ];
}
