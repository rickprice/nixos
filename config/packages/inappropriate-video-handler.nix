{ lib, rustPlatform, fetchFromGitHub, pkg-config, libx11 }:

rustPlatform.buildRustPackage {
  pname = "inappropriate-video-handler";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "InappropriateVideoHandler";
    rev = "2c6c940abefd77567f0d3879000eec618982d6dd";
    hash = "sha256-0V0QZW+ASi3ix6mofZVnE/uU2t8D+uPnjshmD2+Pnvo=";
  };

  cargoHash = "sha256-cuoaQA/gsEDUGTvmBh+B/l4T4q/b7E1TpSVomJose5Q=";

  doCheck = false;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ libx11 ];

  meta = with lib; {
    description = "Handles inappropriate video content";
    homepage = "https://github.com/rickprice/InappropriateVideoHandler";
    license = licenses.mit;
    mainProgram = "inappropriate-video-handler";
    platforms = platforms.linux;
  };
}
