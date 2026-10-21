{ lib
, stdenv
, fetchFromGitHub
, versionCheckHook
, cmake
, pkg-config
, fltk
, libjack2
, liblo
, lilv
, suil
, lv2
, serd
, zix
, clap
, ladspa-header
, lrdf
, pango
, cairo
, libjpeg
, libpng
, fontconfig
, libxfixes
, libxinerama
, libxcursor
, libxext
, libx11
, libxft
, libxrender
}:

stdenv.mkDerivation rec {
  pname = "non-mixer-xt";
  version = "2.0.15";

  src = fetchFromGitHub {
    owner = "Stazed";
    repo = "non-mixer-xt";
    tag = version;
    # Includes the nonlib/FL submodules this needs, plus the ~24 MB
    # Steinberg VST3 SDK submodules (used below, see EnableVST3Support) --
    # simpler and more maintainable than hand-fetching nonlib/FL separately
    # and splicing them in via postUnpack.
    fetchSubmodules = true;
    hash = "sha256-Snsk0PCwpjU8w0DmNsjOhgZlrFBrmlCLVBS5NC8/oNM=";
  };

  # nixpkgs' fltk splits cairo support into a separate static lib that
  # upstream's CMakeLists doesn't know to link against.
  postPatch = ''
    substituteInPlace mixer/CMakeLists.txt \
      --replace-fail \
        ' ''${FLTK_STATIC} ''${FLTK_STATIC_IMAGES} ''${ExternLibraries})' \
        ' ''${FLTK_STATIC} ''${FLTK_STATIC_IMAGES} fltk_cairo ''${ExternLibraries})'
  '';

  nativeBuildInputs = [
    cmake
    pkg-config
    # provides the `fluid` binary that find_package(FLTK) looks for
    fltk
  ];
  buildInputs = [
    fltk
    libjack2
    liblo
    lilv
    suil
    lv2
    serd
    zix
    clap
    ladspa-header
    lrdf
    pango
    cairo
    libjpeg
    libpng
    fontconfig
    libxfixes
    libxinerama
    libxcursor
    libxext
    libx11
    libxft
    libxrender
  ];

  # Both flipped from nixpkgs' upstream defaults (OFF) for this personal
  # build only -- see config/claude/skills/nix-best-practices/SKILL.md for
  # why these two are safe to flip locally but not in the nixpkgs package:
  # NativeOptimizations bakes in -march=native, fine for a per-host build
  # that's never redistributed via a shared binary cache; VST3 support just
  # needs the SDK sources that fetchSubmodules now already pulls in, with
  # no reproducibility or licensing downside (the SDK itself is MIT).
  cmakeFlags = [
    "-DEnableVST3Support=ON"
    "-DNativeOptimizations=ON"
  ];

  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;
  versionCheckProgramArg = "--help";

  meta = with lib; {
    description = "Modular JACK audio mixer with extended LV2, CLAP, VST(2) support (reboot of Non-Mixer)";
    homepage = "https://github.com/Stazed/non-mixer-xt";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    mainProgram = "non-mixer-xt";
  };
}
