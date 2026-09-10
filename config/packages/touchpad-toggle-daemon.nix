{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, udev, xinput }:

rustPlatform.buildRustPackage {
  pname = "touchpad-toggle-daemon";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "touchpad-toggle-daemon";
    rev = "v0.2.2";
    hash = "sha256-D3ZkJRcLJmt+CaYTBc/mQXD1+GLI60p1Qa88cynKUD0=";
  };

  cargoHash = "sha256-ODx8FkMYqAhZ9zdR2RLXQU2Vs4XgmisB4+yY7KgNh8U=";

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ udev ];

  postFixup = ''
    wrapProgram $out/bin/touchpad-toggle-daemon \
      --prefix PATH : ${lib.makeBinPath [ xinput ]}
  '';

  meta = with lib; {
    description = "Disables the laptop touchpad while an external mouse is connected";
    homepage = "https://github.com/rickprice/touchpad-toggle-daemon";
    license = licenses.bsd3;
    mainProgram = "touchpad-toggle-daemon";
    platforms = platforms.linux;
  };
}
