{ lib, stdenv, fetchFromGitHub, qmake, wrapQtAppsHook, qtbase, qttools, rtmidi }:

stdenv.mkDerivation {
  pname = "midisnoop";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "surfacepatterns";
    repo = "midisnoop";
    rev = "bc30f600187e197457cc68f47f8e02cc80b5888c";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ qmake wrapQtAppsHook ];
  buildInputs = [ qtbase qttools rtmidi ];

  # Desktop file install runs a Python script that bakes in absolute paths at
  # build time; skip it and only install the binary.
  postPatch = ''
    sed -i '/INSTALLS += desktop/d' src/src.pro
  '';

  qmakeFlags = [ "PREFIX=${placeholder "out"}" ];

  meta = with lib; {
    description = "MIDI monitor for inspecting MIDI events";
    homepage = "https://github.com/surfacepatterns/midisnoop";
    license = licenses.gpl3Plus;
    mainProgram = "midisnoop";
    platforms = platforms.linux;
  };
}
