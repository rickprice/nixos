{ lib
, stdenv
, fetchFromGitHub
, cmake
, pkg-config
, fltk
, jack2
, liblo
, libsndfile
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
  pname = "non-timeline-xt";
  version = "2.0.9";

  src = fetchFromGitHub {
    owner = "Stazed";
    repo = "non-timeline-xt";
    rev = "5b9e5c072c940251819baee0e9fef4009b6930ca"; # tag 2.0.9
    hash = "sha256-w+BZ9SZ8G3r0wl7rO+vVq1TFt8yrgfX93243OP/3+tA=";
  };

  # Same submodules (and pinned commits) as non-mixer-xt.
  nonlibSrc = fetchFromGitHub {
    owner = "Stazed";
    repo = "nonlib-xt";
    rev = "33b704d638d1383826ea4c36e5607aefabf83371";
    hash = "sha256-RNlKCTn4o2E9h0zXssdyrfretA90MM/aoE5ezG5wpDs=";
  };

  flSrc = fetchFromGitHub {
    owner = "Stazed";
    repo = "non-FL";
    rev = "37158cd7b23d47ab150a82381d7cd3536c473854";
    hash = "sha256-DoEdaQCaohZFQcoaK0HgICQy03IjStD/gPaMbk4rAKA=";
  };

  postUnpack = ''
    rm -rf source/nonlib source/FL
    cp -r --no-preserve=mode,ownership "$nonlibSrc" source/nonlib
    cp -r --no-preserve=mode,ownership "$flSrc" source/FL
  '';

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [
    fltk
    jack2
    liblo
    libsndfile
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

  # Built per-host, not distributed via a shared binary cache, so -march=native
  # is safe here.
  cmakeFlags = [ "-DNativeOptimizations=ON" ];

  # Upstream installs timeline/doc/icon.png as a relative symlink to a path
  # that doesn't exist in the install tree (icons go to share/icons, not
  # share/doc/icons, and the filename differs: non-timeline vs non-timeline-xt).
  postInstall = ''
    rm -f "$out/share/doc/non-timeline-xt/icon.png"
  '';

  meta = with lib; {
    description = "Modular multitrack audio recorder/timeline for JACK (reboot of Non-Timeline/Non-DAW)";
    homepage = "https://github.com/Stazed/non-timeline-xt";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    mainProgram = "non-timeline-xt";
  };
}
