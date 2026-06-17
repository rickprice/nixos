{ lib, stdenv, fetchFromGitHub, lv2, pkg-config }:

stdenv.mkDerivation {
  pname = "volumepanningstereo-lv2";
  version = "0.1.4";

  src = fetchFromGitHub {
    owner = "rickprice";
    repo = "VolumePanningStereo.lv2";
    rev = "v0.1.4";
    hash = "sha256-2xhj5K2hp5qvyxzBb4Hc78h9j5XvXEa9iyaSu8s8gZg=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ lv2 ];

  # -march=native is not reproducible in Nix builds
  postPatch = ''
    sed -i 's/-march=native //' Makefile
  '';

  installPhase = ''
    runHook preInstall
    install -dm755 $out/lib/lv2/volumepanningstereo.lv2
    install -m755 volumepanningstereo.so $out/lib/lv2/volumepanningstereo.lv2/
    install -m644 manifest.ttl volumepanningstereo.ttl $out/lib/lv2/volumepanningstereo.lv2/
    install -Dm644 LICENSE $out/share/licenses/volumepanningstereo-lv2/LICENSE
    runHook postInstall
  '';

  meta = with lib; {
    description = "LV2 plugin that processes stereo input with volume, pan, mute, and bypass controls";
    homepage = "https://github.com/rickprice/VolumePanningStereo.lv2";
    license = licenses.bsd3;
    platforms = platforms.linux;
  };
}
