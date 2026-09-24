{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, alsa-lib, libGL, libxkbcommon, wayland,
  libx11, libxcursor, libxrandr, libxi }:

rustPlatform.buildRustPackage {
  pname = "midi-staff-trainer";
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-staff-trainer";
    rev = "v0.4.5";
    hash = "sha256-BE8wM3TgzW1n3qQtLUg2s2W+rskRlUGRB8yUutrqJus=";
  };

  cargoHash = "sha256-CW2tHplNhwDCubtlRf16v7xT9a/GHqmNm+Xsuv/IMyQ=";

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
