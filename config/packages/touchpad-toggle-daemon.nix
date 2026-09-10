{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, udev, xinput }:

rustPlatform.buildRustPackage {
  pname = "touchpad-toggle-daemon";
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "touchpad-toggle-daemon";
    rev = "v0.2.3";
    hash = "sha256-t2PlLSGY8l+LqlisKwHLi3Kic4G863LI+Hs71G5JPoM=";
  };

  cargoHash = "sha256-f075rYj6z5rhQUtjmOk3O3fS2JI0HSVUkVBQlKi/ZX0=";

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
