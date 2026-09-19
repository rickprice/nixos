{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, alsa-lib, libGL, libxkbcommon, wayland,
  libx11, libxcursor, libxrandr, libxi }:

rustPlatform.buildRustPackage {
  pname = "midi-staff-trainer";
  version = "0-unstable-2026-09-19";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-staff-trainer";
    rev = "abdb19da6f1d053556dd27db4768bca572d2631e";
    hash = "sha256-mvO5gVmpfjAwyuHm8//9toTzetLIyW7jvkvQGIcWuCk=";
  };

  cargoHash = "sha256-NL/hjfymih/SLz5+ogGBMWxc8EvRWhD2qQ5iHzq9Dlw=";

  doCheck = false;

  nativeBuildInputs = [ pkg-config makeWrapper ];

  buildInputs = [
    alsa-lib
    libGL
    libxkbcommon
    wayland
    libx11
    libxcursor
    libxrandr
    libxi
  ];

  postInstall = ''
    wrapProgram $out/bin/midi-staff-trainer \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        libxkbcommon
        libGL
        wayland
      ]}
  '';

  meta = with lib; {
    description = "Interactive MIDI keyboard to musical staff trainer";
    homepage = "https://github.com/rickprice/midi-staff-trainer";
    license = licenses.bsd3;
    mainProgram = "midi-staff-trainer";
    platforms = platforms.linux;
  };
}
