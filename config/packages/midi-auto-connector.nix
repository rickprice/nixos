{ lib, rustPlatform, fetchFromGitHub, pkg-config, alsa-lib, pipewire }:

rustPlatform.buildRustPackage {
  pname = "midi-auto-connector";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-auto-connector";
    rev = "v0.2.0";
    hash = "sha256-XCSWHi+X8zVkgBWnxRYbosExVpZ0WRQiFhLOF2hZmpI=";
  };

  cargoHash = "sha256-U7x59tTNqrafN/T7zaXyooXzd/zU3hH/Laq7BEEaS4Y=";

  nativeBuildInputs = [ pkg-config rustPlatform.bindgenHook ];
  buildInputs = [ alsa-lib pipewire ];

  meta = with lib; {
    description = "A daemon that auto-connects ALSA and PipeWire MIDI ports, and PipeWire audio ports, based on regex rules, with optional Lua hooks on connect/disconnect";
    homepage = "https://github.com/rickprice/midi-auto-connector";
    license = licenses.bsd3;
    mainProgram = "midi-auto-connector";
    platforms = platforms.linux;
  };
}
