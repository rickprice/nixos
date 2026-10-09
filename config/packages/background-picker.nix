{ lib, rustPlatform, fetchCrate, pkg-config, libGL, libxkbcommon, wayland, libx11, libxcursor, libxi, libxrandr, fontconfig }:

rustPlatform.buildRustPackage {
  pname = "background-picker";
  version = "0.3.0";

  src = fetchCrate {
    pname = "background-picker";
    version = "0.3.0";
    hash = "sha256-cMGnvWiX8cvOxeYzrtWCPriR0HUcH6msFmraYMLwKhY=";
  };

  cargoHash = "sha256-Bs3Bn6V2wlBEXE/XTL0Q1n4+13sQrvpdm4ytZGTkvRU=";

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
