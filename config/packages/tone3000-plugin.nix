# TONE3000's own CMakeLists.txt fetches its build dependencies over the
# network at configure time: JUCE/googletest/clap-juce-extensions/freetype
# via CPM (which itself downloads the CPM.cmake bootstrap module too), plus
# two git submodules (NeuralAmpModelerCore, AudioDSPTools) that each nest
# Eigen (and NAM nests AudioDSPTools again). None of that works inside the
# Nix build sandbox.
#
# The CPM.cmake bootstrap (cmake/cpm.cmake) is handled by pre-dropping the
# exact release asset it would otherwise file(DOWNLOAD) into libs/cpm/.
#
# The four CPM-fetched deps (JUCE/googletest/clap-juce-extensions/freetype)
# are copied into the exact SOURCE_DIR path each CPMAddPackage() call already
# names (libs/juce, libs/googletest, libs/clap-juce-extensions, libs/freetype)
# -- matching upstream's own CI, which caches those same in-tree directories
# across runs instead of re-downloading them. Just pre-populating those
# directories isn't enough on its own though: CPM.cmake 0.40.2 still runs an
# ExternalProject git-clone step against an explicit SOURCE_DIR argument
# regardless of whether it's already populated (confirmed: that path failed
# here with "could not find git for clone of freetype-populate" even with
# libs/freetype pre-populated). What actually short-circuits the network
# fetch is CPM's per-package override variable, `CPM_<NAME>_SOURCE` (NAME is
# CPMAddPackage's own NAME arg, e.g. `JUCE`, `GOOGLETEST`,
# `clap-juce-extensions`, `freetype`): CPMAddPackage checks that variable
# before anything else and, when set, recurses with ONLY SOURCE_DIR (dropping
# GIT_REPOSITORY/GIT_TAG entirely), so FetchContent has no download method
# left to run and just uses the directory as-is -- set in preConfigure below
# (not the static cmakeFlags list) since it needs an absolute path built from
# $sourceRoot, which isn't known until build time.
#
# The in-tree copy (rather than pointing CPM_<NAME>_SOURCE straight at the
# read-only /nix/store paths) matters for a second reason, not just fidelity
# to upstream's CI: plugin/CMakeLists.txt calls source_group(TREE
# ${CMAKE_SOURCE_DIR} ...) over JUCE's sources, and CMake's source_group
# hard-errors ("ROOT: ... is not a prefix of file: ...") if any of those
# files live outside CMAKE_SOURCE_DIR -- confirmed by trying the store-path
# shortcut first and hitting exactly that error for juce_analytics.cpp.
#
# NeuralAmpModelerCore/AudioDSPTools are plain git submodules the project
# add_subdirectory()s directly (no CPM involved), so those two really do need
# real writable files sitting at plugin/NeuralAmpModelerCore and
# plugin/AudioDSPTools; postUnpack copies them into place the same way.
{ lib
, stdenv
, fetchFromGitHub
, fetchurl
, cmake
, pkg-config
, gtk3
, alsa-lib
, libjack2
, curl
, freetype
, fontconfig
, libGL
, libglvnd
, libX11
, libXext
, libXrandr
, libXinerama
, libXcursor
, libXrender
, libsysprof-capture
}:

let
  version = "0.0.12";

  juceSrc = fetchFromGitHub {
    owner = "juce-framework";
    repo = "JUCE";
    tag = "9.0.3";
    hash = "sha256-eB5HvUiKXRAp53EApiX0jGNhXVtt83zD9TaNOhdQIjc=";
  };

  googletestSrc = fetchFromGitHub {
    owner = "google";
    repo = "googletest";
    tag = "v1.15.2";
    hash = "sha256-1OJ2SeSscRBNr7zZ/a8bJGIqAnhkg45re0j3DtPfcXM=";
  };

  # fetchSubmodules: nests clap-libs/clap and clap-libs/clap-helpers.
  clapJuceExtensionsSrc = fetchFromGitHub {
    owner = "free-audio";
    repo = "clap-juce-extensions";
    rev = "c1a5ad025f95d01e03267857fa8276ebeed16500";
    hash = "sha256-P8rLNI9fXGU8yxXXdOkRD/+T3AMd3zdRM8mHp62dEmA=";
    fetchSubmodules = true;
  };

  # Linked statically into the Linux GUI targets (see CMakeLists.txt); pinned
  # to the exact tag T3K's own CPMAddPackage call fetches.
  freetypeSrc = fetchFromGitHub {
    owner = "freetype";
    repo = "freetype";
    tag = "VER-2-13-3";
    hash = "sha256-4l90lDtpgm5xlh2m7ifrqNy373DTRTULRkAzicrM93c=";
  };

  cpmScript = fetchurl {
    url = "https://github.com/cpm-cmake/CPM.cmake/releases/download/v0.40.2/CPM.cmake";
    hash = "sha256-yM3DLAOBZTjOInge1ylk3IZLKjSjENO3EEgSpcotg10=";
  };

  # Git submodules, fetched recursively since each nests Eigen (and
  # NeuralAmpModelerCore nests AudioDSPTools again under it).
  neuralAmpModelerCoreSrc = fetchFromGitHub {
    owner = "sdatkinson";
    repo = "NeuralAmpModelerCore";
    rev = "1f42f88535884450104b8711d7595019afa0495b";
    hash = "sha256-IHBllDeZqiwwYAgKD+O22T6rmlXihNLfwD2GzosqV9M=";
    fetchSubmodules = true;
  };

  audioDspToolsSrc = fetchFromGitHub {
    owner = "sdatkinson";
    repo = "AudioDSPTools";
    rev = "0827c6c2fc0deced568536142ea86f189e0b98a1";
    hash = "sha256-YIlYUT3Ju1lGXKmgTmKJMZ9XJQjHWAeCunLOuGvdHZQ=";
    fetchSubmodules = true;
  };
in

stdenv.mkDerivation {
  pname = "tone3000-plugin";
  inherit version;

  src = fetchFromGitHub {
    owner = "tone-3000";
    repo = "tone3000-plugin";
    tag = "v${version}";
    hash = "sha256-sF3iLSkEu/C4W1xLZsS6+Lz0RXhLDeZUpwcqdvNr6qQ=";
  };

  postUnpack = ''
    mkdir -p "$sourceRoot/libs/cpm"
    install -m644 "${cpmScript}" "$sourceRoot/libs/cpm/CPM_0.40.2.cmake"

    cp -r --no-preserve=mode,ownership "${juceSrc}" "$sourceRoot/libs/juce"
    cp -r --no-preserve=mode,ownership "${googletestSrc}" "$sourceRoot/libs/googletest"
    cp -r --no-preserve=mode,ownership "${clapJuceExtensionsSrc}" "$sourceRoot/libs/clap-juce-extensions"
    cp -r --no-preserve=mode,ownership "${freetypeSrc}" "$sourceRoot/libs/freetype"

    rm -rf "$sourceRoot/plugin/NeuralAmpModelerCore" "$sourceRoot/plugin/AudioDSPTools"
    cp -r --no-preserve=mode,ownership "${neuralAmpModelerCoreSrc}" "$sourceRoot/plugin/NeuralAmpModelerCore"
    cp -r --no-preserve=mode,ownership "${audioDspToolsSrc}" "$sourceRoot/plugin/AudioDSPTools"
  '';

  # CPM_<NAME>_SOURCE needs an absolute path built from $sourceRoot, which
  # isn't known at Nix-eval time -- set here via cmakeFlagsArray instead of
  # the static cmakeFlags list. preConfigure runs before cmakeConfigurePhase
  # cd's into the build/ subdirectory, so $PWD is still $sourceRoot here.
  preConfigure = ''
    cmakeFlagsArray+=(
      "-DCPM_JUCE_SOURCE=$PWD/libs/juce"
      "-DCPM_GOOGLETEST_SOURCE=$PWD/libs/googletest"
      "-DCPM_clap-juce-extensions_SOURCE=$PWD/libs/clap-juce-extensions"
      "-DCPM_freetype_SOURCE=$PWD/libs/freetype"
    )
  '';

  nativeBuildInputs = [ cmake pkg-config ];

  buildInputs = [
    gtk3
    alsa-lib
    libjack2
    curl
    freetype
    fontconfig
    libGL
    libglvnd
    libX11
    libXext
    libXrandr
    libXinerama
    libXcursor
    libXrender
    libsysprof-capture
  ];

  cmakeFlags = [
    (lib.cmakeFeature "CMAKE_TOOLCHAIN_FILE" "cmake/linux-toolchain.cmake")
    (lib.cmakeBool "BUILD_AAX" false)
  ];

  cmakeBuildType = "Release";

  # curl and libjack are dlopened lazily at runtime by design (T3K's own
  # CMakeLists.txt: "no link-time libcurl dependency" / "adds no runtime
  # dependency" so a non-Nix build doesn't need curl-dev or a JACK server
  # present), and JUCE's X11 backend dlopens libX11/libXext/libXcursor/
  # libXinerama/libXrandr the same way (see nixpkgs' own chow-tape-model
  # package, which documents the same JUCE behaviour). None of that produces
  # a DT_NEEDED entry, so Nix's rpath-shrinking would otherwise drop these
  # libs from the closure entirely (nothing references them) -- forcing an
  # actual link via NIX_LDFLAGS, same as chow-tape-model does for the X11
  # libs, keeps them in rpath so the dlopen calls resolve at runtime
  # regardless of which host process loads the plugin.
  env.NIX_LDFLAGS = toString [
    "-lX11"
    "-lXext"
    "-lXcursor"
    "-lXinerama"
    "-lXrandr"
    "-lcurl"
    "-ljack"
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/vst3 $out/lib/lv2 $out/lib/clap
    # plugin/CMakeLists.txt is add_subdirectory()'d from the root, so its
    # binary dir (and therefore the artefacts dir) is build/plugin, not build.
    cd plugin/TONE3000_artefacts/Release
    cp -r VST3/TONE3000.vst3 $out/lib/vst3/
    cp -r LV2/TONE3000.lv2 $out/lib/lv2/
    cp -r CLAP/TONE3000.clap $out/lib/clap/
    cp Standalone/TONE3000 $out/bin/

    runHook postInstall
  '';

  meta = {
    description = "Free, open-source Neural Amp Modeler-based guitar/bass amp & cab simulator with access to the TONE3000 tone library";
    homepage = "https://www.tone3000.com/plugin";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "TONE3000";
  };
}
