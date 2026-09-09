{ lib, rustPlatform, fetchFromGitHub, pkg-config, makeWrapper, udev, xinput }:

rustPlatform.buildRustPackage {
  pname = "touchpad-toggle-daemon";
  version = "0.2.1";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "touchpad-toggle-daemon";
    rev = "v0.2.1";
    hash = "sha256-UMKFnSby9AWx8phZeS5sCnXg7jqTnd6TdS+VkZ7Qu8I=";
  };

  cargoHash = "sha256-w935JQlnoDOi/sZUBC+kqTKhjyzAPyAzc6FhG6n07i0=";

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
