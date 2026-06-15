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

  nativeBuildInputs = [ qmake wrapQtAppsHook pkg-config ];
  buildInputs = [ qtbase qttools rtmidi ];

  postPatch = ''
    # Explicit QObject include so Q_OBJECT expands correctly when moc_engine.cpp
    # is compiled — QStringList/QVector don't pull it in transitively in Qt 5.15
    sed -i 's|#include <QtCore/QByteArray>|#include <QtCore/QByteArray>\n#include <QtCore/QObject>|' src/engine.h

    # RtError was renamed to RtMidiError in rtmidi 2.1; add a compat typedef
    sed -i 's|#include "error.h"|#include "error.h"\ntypedef RtMidiError RtError;|' src/engine.cpp

    # WINDOWS_KS was removed from RtMidi::Api in rtmidi 6.x
    sed -i '/case RtMidi::WINDOWS_KS:/,+2d' src/engine.cpp

    # Use pkg-config so qmake picks up rtmidi's include path automatically
    sed -i 's|CONFIG += console warn_on|CONFIG += console link_pkgconfig warn_on|' src/src.pro
    sed -i 's|LIBS += -lrtmidi|PKGCONFIG += rtmidi|' src/src.pro

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
