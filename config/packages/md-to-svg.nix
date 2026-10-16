{ lib, rustPlatform, fetchFromGitHub }:

rustPlatform.buildRustPackage {
  pname = "md-to-svg";
  version = "0.2.4";

  src = fetchFromGitHub {
    owner = "noahprice-dev";
    repo = "md-to-svg";
    rev = "v0.2.4";
    hash = "sha256-vJS4JOX+dIXTq/5SCQ9jTWbLw1SXc35UjJf7wbD17GA=";
  };

  cargoHash = "sha256-II1ShtlZhadDK3y7kp+IUP172MZwbnLiyY25EOc2kdM=";

  meta = with lib; {
    description = "Highly configurable CLI tool to translate Markdown Documents into SVG files";
    homepage = "https://github.com/noahprice-dev/md-to-svg";
    license = licenses.bsd3;
    mainProgram = "md_to_svg";
    platforms = platforms.linux;
  };
}
