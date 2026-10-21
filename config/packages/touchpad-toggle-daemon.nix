{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, udev, xinput, versionCheckHook }:

rustPlatform.buildRustPackage rec {
  pname = "touchpad-toggle-daemon";
  version = "0.2.6";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "touchpad-toggle-daemon";
    rev = "v${version}";
    hash = "sha256-xZE4ovRPC2QUmU4KY+LPLL8hiIQ8cdOEI7EeiWKYnQE=";
  };

  cargoHash = "sha256-ld9CmccLkfIiEzXt6Ewsh9FxG+yI4ln57cs9EbX3K4Y=";

  nativeBuildInputs = [ pkg-config makeWrapper ];
  buildInputs = [ udev ];

  postFixup = ''
    wrapProgram $out/bin/touchpad-toggle-daemon \
      --prefix PATH : ${lib.makeBinPath [ xinput ]}
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = with lib; {
    description = "Disables the laptop touchpad while an external mouse is connected";
    homepage = "https://github.com/rickprice/touchpad-toggle-daemon";
    license = licenses.bsd3;
    mainProgram = "touchpad-toggle-daemon";
    platforms = platforms.linux;
  };
}
