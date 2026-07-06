{ lib, rustPlatform, fetchFromGitHub, pkg-config, libx11 }:

rustPlatform.buildRustPackage {
  pname = "inappropriate-video-handler";
  version = "0.4.3";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "InappropriateVideoHandler";
    rev = "v0.4.3";
    hash = "sha256-eSUVLhCwzodg6UZQW7sc4bU//qKz1ojvQwhbgrm0y94=";
  };

  cargoHash = "sha256-1F5GA8xpQyO52nKu3JC4ZjvRMhKoYCw5Fb4c2C06Lsc=";

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
