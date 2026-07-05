{ lib, rustPlatform, fetchFromGitHub, pkg-config, libx11 }:

rustPlatform.buildRustPackage {
  pname = "inappropriate-video-handler";
  version = "0.4.2";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "InappropriateVideoHandler";
    rev = "v0.4.2";
    hash = "sha256-HCiKZIgBbxo3BjPeD9EqM3g26lqFUtBqUzOIvwQq+eQ=";
  };

  cargoHash = "sha256-CTo1U0DRoDAt4V2ku62FoWm0ZGgiX0JMrfCeNgNbii4=";

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
