{ lib, stdenv, fetchFromGitHub, qmake, wrapQtAppsHook, qtbase, qttools, rtmidi, pkg-config }:

stdenv.mkDerivation {
  pname = "midisnoop";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "surfacepatterns";
    repo = "midisnoop";
    rev = "bc30f600187e197457cc68f47f8e02cc80b5888c";
    hash = "sha256-XDpDfTq5sAHqeYk3j+HA9H0SGq5sawrLzdK2rqN9fv4=";
  };

  patches = [
    # typedef RtMidiError RtError (renamed in rtmidi 2.1) + drop WINDOWS_KS
    ./patches/03-fix_build_with_rtmidi_2_1.patch
    # use PKGCONFIG += rtmidi so qmake picks up include paths via pkg-config
    ./patches/04-rtmidi-pkgconfig.patch
    # add explicit #include <QtCore/QObject> to fix Qt5 MOC staticMetaObject error
    ./patches/0005-src-engine.h-another-qt5-fix.patch
  ];

  nativeBuildInputs = [ qmake wrapQtAppsHook pkg-config ];
  buildInputs = [ qtbase qttools rtmidi ];

  postPatch = ''
    # Desktop file install runs a Python script that bakes in absolute paths;
    # skip it and only install the binary.
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
