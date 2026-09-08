{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, udev, xinput }:

rustPlatform.buildRustPackage {
  pname = "touchpad-toggle-daemon";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "touchpad-toggle-daemon";
    rev = "v0.2.0";
    hash = "sha256-tXVKEP57pf67jXK2uYAYdAtaRmRgzPwzjnHeloV0OJw=";
  };

  cargoHash = "sha256-ekKMR4y5rZzJvev6uBQFRMS3msvXs9hLWnrcQA6Vaf0=";

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
