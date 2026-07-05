{ lib, rustPlatform, fetchFromGitHub, pkg-config, libx11 }:

rustPlatform.buildRustPackage {
  pname = "inappropriate-video-handler";
  version = "0.4.1";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "InappropriateVideoHandler";
    rev = "v0.4.1";
    hash = "sha256-1t7k0ZdxFTbbPYnagVLNc/qyPGi9RfxtVcfwdSMuopo=";
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
