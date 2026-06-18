{ lib, rustPlatform, fetchCrate, pkg-config, libGL, libxkbcommon, wayland, libx11, libxcursor, libxi, libxrandr, fontconfig }:

rustPlatform.buildRustPackage {
  pname = "background-picker";
  version = "0.1.0";

  src = fetchCrate {
    pname = "background-picker";
    version = "0.1.0";
    hash = "sha256-LE5PdIw+90x3JZOxc7F06v8E8HR7gLFjSOoor+DIm+o=";
  };

  cargoHash = "sha256-F2iSLBtpzAur6+mLWKKnuBXC6K6yiCvQwyCzx7bqKOQ=";

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
