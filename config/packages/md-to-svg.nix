{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "md-to-svg";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "noahprice-dev";
    repo = "md-to-svg";
    rev = "v0.2.2";
    hash = "sha256-3nDzVEqSudT6Sg+CYI3IuzEydXyfLa/hAkTpTzJ6eHE=";
  };

  cargoHash = "sha256-TOpRWICLpN7mtYe0rYFQqm/2ZmjcKYB7llU/mpqeOTI=";

  meta = with lib; {
    description = "Highly configurable CLI tool to translate Markdown Documents into SVG files";
    homepage = "https://github.com/noahprice-dev/md-to-svg";
    license = licenses.bsd3;
    mainProgram = "md_to_svg";
    platforms = platforms.linux;
  };
}
