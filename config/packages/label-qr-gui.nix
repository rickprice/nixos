{
  lib,
  rustPlatform,
  fetchCrate,
  pkg-config,
  makeWrapper,
  libxkbcommon,
  wayland,
  libGL,
  libx11,
  libxcursor,
  libxrandr,
  libxi,
  alsa-lib,
  xdg-utils,
}:

let
  # winit's X11 backend dlopen()s libxkbcommon-x11 by name at runtime rather
  # than linking it, so patchelf's automatic RPATH fixup doesn't cover it --
  # wrap the binary with LD_LIBRARY_PATH instead (see postFixup below).
  guiLibs = [
    libxkbcommon
    wayland
    libGL
    libx11
    libxcursor
    libxrandr
    libxi
  ];
in
rustPlatform.buildRustPackage rec {
  pname = "label-qr-gui";
  version = "0.5.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-hofFnGaUv508jJVjRzJpbx/DOgCS60ng12S09Cd2XHo=";
  };

  cargoHash = "sha256-b9Kh8m+2ckjxatQe64zU0KoW+2nM5jgDtDmoEyxr/8Y=";

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];
  # alsa-lib: the Timecode Warble feature links ALSA via cpal -- a
  # *build-time* link dependency here (unlike photo-splitter's ffmpeg,
  # which is only shelled out to at runtime).
  buildInputs = guiLibs ++ [ alsa-lib ];

  # xdg-utils: v0.4.0 added a "Print" button that shells out to
  # xdg-open (runtime only, same reasoning as photo-splitter's ffmpeg).
  postFixup = ''
    wrapProgram $out/bin/label-qr-gui \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath (guiLibs ++ [ alsa-lib ])}" \
      --prefix PATH : "${lib.makeBinPath [ xdg-utils ]}"
  '';

  meta = {
    description = "Fullscreen field-label entry appliance with a large QR-code readout";
    homepage = "https://github.com/rickprice/field-label-tools";
    license = lib.licenses.mit;
    mainProgram = "label-qr-gui";
    platforms = lib.platforms.linux;
  };
}
