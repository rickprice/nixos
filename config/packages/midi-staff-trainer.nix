{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, alsa-lib, libGL, libxkbcommon, wayland,
  libx11, libxcursor, libxrandr, libxi, versionCheckHook }:

rustPlatform.buildRustPackage rec {
  pname = "midi-staff-trainer";
  version = "0.4.13";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "midi-staff-trainer";
    rev = "v${version}";
    hash = "sha256-NuU7/LZD4TPnHvRpTyxwt4VzB1IupJRB5W98bRGH7ME=";
  };

  cargoHash = "sha256-MDemjCY3qLrU0i51Gs6GqitjBh4Y+AFj74dBd1/5qk8=";

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

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = with lib; {
    description = "Interactive MIDI keyboard to musical staff trainer";
    homepage = "https://github.com/rickprice/midi-staff-trainer";
    license = licenses.bsd3;
    mainProgram = "midi-staff-trainer";
    platforms = platforms.linux;
  };
}
