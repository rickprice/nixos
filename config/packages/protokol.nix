{ lib
, stdenv
, fetchurl
, makeWrapper
, autoPatchelfHook
, dpkg
, alsa-lib
, curl
, avahi
, jack2
, libxcb
, libx11
, libxcursor
, libxext
, libxi
, libxinerama
, libxrandr
, libxrender
, libxxf86vm
, libglvnd
, zenity
}:

let
  runLibDeps = [
    curl
    avahi
    jack2
    libxcb
    libx11
    libxcursor
    libxext
    libxi
    libxinerama
    libxrandr
    libxrender
    libxxf86vm
    libglvnd
  ];

  runBinDeps = [
    zenity
  ];
in

stdenv.mkDerivation rec {
  pname = "protokol";
  version = "0.6.7.140";

  src = fetchurl {
    url = "https://hexler.net/pub/${pname}/${pname}-${version}-linux-x64.deb";
    hash = "sha256-/luBSmLEr3zhWVX+KT5FHMAQUa4eNnECbJJjM6fdbCo=";
  };

  strictDeps = true;

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    alsa-lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r usr/share $out/share

    mkdir -p $out/bin
    cp opt/protokol/Protokol $out/bin/Protokol

    substituteInPlace $out/share/applications/protokol.desktop \
      --replace-fail "Exec=/opt/protokol/Protokol" "Exec=$out/bin/Protokol"

    wrapProgram $out/bin/Protokol \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runLibDeps} \
      --prefix PATH : ${lib.makeBinPath runBinDeps}

    runHook postInstall
  '';

  meta = {
    homepage = "https://hexler.net/protokol";
    description = "Development tool to monitor MIDI, OSC, and gamepad input streams";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "Protokol";
  };
}
