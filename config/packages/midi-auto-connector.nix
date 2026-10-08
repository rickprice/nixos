{ lib, rustPlatform, fetchFromGitHub, pkg-config, alsa-lib, pipewire }:

rustPlatform.buildRustPackage {
  pname = "midi-auto-connector";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-auto-connector";
    rev = "v0.3.0";
    hash = "sha256-rma3uhXRhOTmRofbkPXJ/8C+MW4LV1wQhrTJm6YrXvc=";
  };

  cargoHash = "sha256-Og2vgWKa0g5fs564FyNsOjVB4xzytpdrOO1Trk1zU5A=";

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
