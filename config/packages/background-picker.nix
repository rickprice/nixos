{ lib, rustPlatform, fetchCrate, pkg-config, makeWrapper, libGL, libxkbcommon, wayland, libx11, libxcursor, libxi, libxrandr, fontconfig, versionCheckHook }:

rustPlatform.buildRustPackage rec {
  pname = "background-picker";
  version = "0.3.1";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-AeUAjVtG3DdQAjgRWsy95UlgnnPYsGrZjd3NhCNPQwA=";
  };

  cargoHash = "sha256-4ZlNgrZpn0fF4iRFWiDJHXNnXdW5rWw7Kr4RVHJz1fQ=";

  nativeBuildInputs = [ pkg-config makeWrapper ];

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

  postInstall = ''
    wrapProgram $out/bin/background-picker \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [
        libxkbcommon
        libGL
        wayland
      ]}
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = with lib; {
    description = "Allow user to select a background from a directory hierarchy";
    homepage = "https://github.com/rickprice/BackgroundPicker";
    license = licenses.bsd3;
    mainProgram = "background-picker";
    platforms = platforms.linux;
  };
}
