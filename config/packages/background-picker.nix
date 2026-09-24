{ lib, rustPlatform, fetchCrate, pkg-config, libGL, libxkbcommon, wayland, libx11, libxcursor, libxi, libxrandr, fontconfig }:

rustPlatform.buildRustPackage {
  pname = "background-picker";
  version = "0.2.1";

  src = fetchCrate {
    pname = "background-picker";
    version = "0.2.1";
    hash = "sha256-bBsQgud+M4rTlogib1g9AlsJGDcCmqxz6WkeBaVYCCM=";
  };

  cargoHash = "sha256-6KO4qVt1ghuKbMkuVlsRTSRMUyyOi9Cuh2v3WFpYzL8=";

  nativeBuildInputs = [ pkg-config ];

  preCheck = ''
    export HOME=$(mktemp -d)
  '';

  buildInputs = [
    libGL
    libxkbcommon
    wayland
    libx11
    libxcursor
    libxi
    libxrandr
    fontconfig
  ];

  meta = with lib; {
    description = "Allow user to select a background from a directory hierarchy";
    homepage = "https://github.com/rickprice/BackgroundPicker";
    license = licenses.bsd3;
    mainProgram = "background-picker";
    platforms = platforms.linux;
  };
}
