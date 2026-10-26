{
  symlinkJoin,
  makeWrapper,
  guitarix,
  pipewire,
}:

# Guitarix links against JACK, not PipeWire's JACK-compatible library, so
# without this wrapper its JACK backend can't connect to PipeWire and the
# amp sim never initializes. Carla is wrapped the same way, for the same
# reason.
symlinkJoin {
  name = "guitarix";
  paths = [ guitarix ];
  nativeBuildInputs = [ makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/guitarix \
      --prefix LD_LIBRARY_PATH : "${pipewire.jack}/lib"
  '';
}
