{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "md-to-svg";
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "noahprice-dev";
    repo = "md-to-svg";
    rev = "v0.2.3";
    hash = "sha256-y2a2KBjUOHOSfC2kSD7RZaLlJH92nNOY6L3pQhai/P0=";
  };

  cargoHash = "sha256-s0+r1+++jTFSVCj0Sm4UtE7KMNQrIb9FOcf4E2BvuVM=";

  meta = with lib; {
    description = "Highly configurable CLI tool to translate Markdown Documents into SVG files";
    homepage = "https://github.com/noahprice-dev/md-to-svg";
    license = licenses.bsd3;
    mainProgram = "md_to_svg";
    platforms = platforms.linux;
  };
}
