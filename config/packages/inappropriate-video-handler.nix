{ lib, rustPlatform, fetchFromGitHub, pkg-config, libx11 }:

rustPlatform.buildRustPackage {
  pname = "inappropriate-video-handler";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "InappropriateVideoHandler";
    rev = "v0.3.0";
    hash = "sha256-S4QKYwk5o2Tg4NiMqxQ1RdcJ2rZyfLwzIbN4LBwdykA=";
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
